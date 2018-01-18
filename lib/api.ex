defmodule Ak.Api do
  use HTTPotion.Base
  import ShortMaps

  # --------------- Process request ---------------
  defp process_url(url) do
    base = Application.get_env(:actionkit, :base)
    cond do
      String.ends_with?(url, "/") -> "#{base}/rest/v1/#{url}"
      String.length(url) == 0 -> "#{base}/rest/v1/"
      true -> "#{base}/rest/v1/#{url}/"
    end
  end

  defp process_request_headers(hdrs) do
    Enum.into(hdrs, Accept: "application/json", "Content-Type": "application/json")
  end

  defp process_options(opts) do
    username = Application.get_env(:actionkit, :username)
    password = Application.get_env(:actionkit, :password)
    Keyword.put(opts, :basic_auth, {username, password})
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
      _ -> text
    end
  end

  # -----------------------------------
  # ---------- STREAM HELPERS ---------
  # -----------------------------------
  # If results exist, send them, passing only the tail
  defp unfolder(%{"meta" => meta, "objects" => [head | tail]}) do
    {head, %{"meta" => meta, "objects" => tail}}
  end

  # If results don't exist (because above would have matched),
  # and meta.next is nil, we're done (base case)
  defp unfolder(%{"meta" => %{"next" => nil}, "objects" => _}) do
    nil
  end

  # If results don't exist (first clause matches), and next is not null, serve it
  defp unfolder(%{"meta" => %{"next" => "/rest/v1/" <> url}, "objects" => _}) do
    [core, params] = String.split(url, "?")
    case get(core, [query: Plug.Conn.Query.decode(params)]).body do
      %{"meta" => meta, "objects" => [head | tail]} ->
        {head, %{"meta" => meta, "objects" => tail}}
      _ ->
        nil
    end
  end

  # Handle errors
  defp unfolder({:error, message}) do
    message
  end

  @doc """
  Wraps any Nationbuilder style paginatable endpoint in a stream for repeated fetching

  For example, `Nb.Api.stream("people") |> Enum.take(500)` will make 5 requests
  to Nationbuilders `/people`, using the token returned to fetch the next page.

  Can be used for any Nationbuilder endpoint that has a response in the format
  {
    "next": "/api/v1/people?__nonce=3OUjEzI6iyybc1F3sk6YrQ&__token=ADGvBW9wM69kUiss1KqTIyVeQ5M6OwiL6ttexRFnHK9m",
    "prev": null,
    "results" [
      ...
    ]
  }
  """
  def stream(url, opts \\ []) do
    get(url, opts).body
    |> Stream.unfold(&unfolder/1)
  end
end
