defmodule Ak.DialerLogin do
  import ShortMaps

  # Returns a login or nil
  def existing_login_for_email(email, client) do
    %{body: ~m(objects)} = Ak.Api.get("user", query: ~m(email))
    user = List.first(objects)

    case user do
      nil ->
        nil

      ~m(token) ->
        [_, user_id, _] = String.split(token, ".")
        login_claimed_by_user_today(user_id, client)
    end
  end

  # Returns a login or nil
  def login_claimed_by_user_today(user, client) do
    %{"id" => page} = Ak.Signup.page_matching(&(&1["name"] == "claim-login-#{client}"))
    order_by = "-created_at"

    claimed_by_user_today =
      Ak.Api.stream("action", query: ~m(page order_by))
      |> Enum.take_while(&claimed_today/1)
      |> IO.inspect()
      |> Enum.filter(fn action -> matches_user(action, user) end)

    case List.first(claimed_by_user_today) do
      %{"fields" => %{"claimed" => login}} -> login
      nil -> nil
    end
  end

  def record_login_claimed(user_info, action_claimed, client, should_subscribe \\ false) do
    page = "claim-login-#{client}"
    body = Map.merge(user_info, ~m(page action_claimed))
    body = if should_subscribe, do: Map.put(body, "opt_in", true), else: body

    Ak.Api.post("action", body: body)
  end

  def who_claimed(client, login) do
    %{"id" => page} = Ak.Signup.page_matching(&(&1["name"] == "claim-login-#{client}"))
    order_by = "-created_at"

    match =
      Ak.Api.stream("action", query: ~m(page order_by))
      |> Enum.reduce_while(nil, fn action, _ ->
        if matches_login(action, login) do
          {:halt, action}
        else
          {:cont, nil}
        end
      end)

    case match do
      %{"user" => "/rest/v1/" <> user, "fields" => fields} ->
        %{body: body = %{"phones" => phones}} = Ak.Api.get(user)

        phone_number =
          case List.last(phones) do
            "/rest/v1/" <> phone_uri ->
              %{body: %{"normalized_phone" => phone_number}} = Ak.Api.get(phone_uri)
              phone_number

            _ ->
              nil
          end

        calling_from = Map.get(fields, "calling_from", "unknown")

        body
        |> Map.put("calling_from", calling_from)
        |> Map.put("phone", phone_number)

      nil ->
        nil
    end
  end

  def matches_login(%{"fields" => ~m(claimed)}, login) do
    String.downcase(claimed) == String.downcase(login)
  end

  def matches_user(%{"user" => "/rest/v1/user/" <> user_path}, user_id) do
    String.trim(user_path, "/") == user_id
  end

  def claimed_today(~m(created_at)) do
    claimed_at = Ak.Helpers.in_pst(created_at)
    Timex.day(Timex.now("America/Los_Angeles")) == Timex.day(claimed_at)
  end
end
