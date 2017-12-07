defmodule Ak.DialerLogin do
  import ShortMaps

  # Returns a login or nil
  def existing_login_for_email(email) do
    %{body: ~m(objects)} = Ak.Api.get("user", query: ~m(email))
    user = List.first(objects)

    case user do
      nil ->
        nil

      ~m(token) ->
        [_, user_id, _] = String.split(token, ".")
        login_claimed_by_user_today(user_id)
    end
  end

  # Returns a login or nil
  def login_claimed_by_user_today(user) do
    page = 30
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

  def record_login_claimed(user_info, action_claimed) do
    page = "claim-login"
    Ak.Api.post("action", body: Map.merge(user_info, ~m(page action_claimed)))
  end
end
