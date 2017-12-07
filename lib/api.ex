defmodule Ak.Api do
  use HTTPotion.Base
  import ShortMaps

  @base Application.get_env(:actionkit, :base)
  @username Application.get_env(:actionkit, :username)
  @password Application.get_env(:actionkit, :password)

  # --------------- Process request ---------------
  defp process_url(url) do
    cond do
      String.ends_with?(url, "/") -> "#{@base}/rest/v1/#{url}"
      String.length(url) == 0 -> "#{@base}/rest/v1/"
      true -> "#{@base}/rest/v1/#{url}/"
    end
  end

  defp process_request_headers(hdrs) do
    Enum.into(hdrs, Accept: "application/json", "Content-Type": "application/json")
  end

  defp process_options(opts) do
    Keyword.put(opts, :basic_auth, {@username, @password})
  end

  defp process_request_body(body) when is_map(body) do
    case Poison.encode(body) do
      {:ok, encoded} -> encoded
      {:error, _problem} -> body
    end
  end

  defp process_request_body(body) do
    body
  end

  # --------------- Process response ---------------
  defp process_response_body(text) do
    case Poison.decode(text) do
      {:ok, body} -> body
      {:error, _raw, _} -> text
    end
  end

  def stream(url) do
    %{body: ~m(objects)} = get(url)
    objects
  end
end
