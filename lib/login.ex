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
    %{"id" => page} = Ak.Signup.page_matching(& &1["name"] == "claim-login-#{client}")
    %{body: ~m(objects)} = Ak.Api.get("action", query: ~m(user page))

    claimed_today =
      Enum.filter(objects, fn ~m(created_at) ->
        claimed_at = Ak.Helpers.in_est(created_at)
        Timex.day(Timex.now()) == Timex.day(claimed_at)
      end)

    case List.first(claimed_today) do
      %{"fields" => %{"claimed" => login}} -> login
      nil -> nil
    end
  end

  def record_login_claimed(user_info, action_claimed, client) do
    page = "claim-login-#{client}"
    Ak.Api.post("action", body: Map.merge(user_info, ~m(page action_claimed)))
  end

  def who_claimed(client, login) do
    %{"id" => page} = Ak.Signup.page_matching(& &1["name"] == "claim-login-#{client}")
    order_by = "-created_at"

    claimed_today =
      Ak.Api.stream("action", query: ~m(page order_by))
      |> Enum.take_while(fn ~m(created_at) ->
        claimed_at = Ak.Helpers.in_est(created_at)
        Timex.day(claimed_at) == Timex.day(Timex.now() |> Timex.shift(hours: -6))
      end)

    matches = Enum.filter(claimed_today, fn %{"fields" => %{"claimed" => login_claimed}} ->
      String.downcase(login_claimed) == String.downcase(login)
    end)

    case List.first(matches) do
      %{"user" => "/rest/v1/" <> user, "fields" => fields} ->
        %{body: body} = Ak.Api.get(user)
        calling_from = Map.get("fields", "calling_from", "unknown")
        Map.put(body, "calling_from", calling_from)
      nil -> nil
    end
  end
end
