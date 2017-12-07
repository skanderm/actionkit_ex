defmodule Ak.Petition do
  use Agent
  import ShortMaps

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # Scrapes available petition pages, return the action attribute for the one
  # matching &func/1, which is passed a map with a title attribute
  # like Signup: John Heenan
  def name_for_petition_with_slug(slug) do
    existing_match =
      Agent.get(__MODULE__, fn list ->
        matches = Enum.filter(list, &(&1["name"] == slug)) |> List.first()
      end)

    if existing_match != nil do
      existing_match["name"]
    else
      all_petition_pages = Ak.Api.stream("petitionpage")
      Agent.update(__MODULE__, fn _ -> all_petition_pages end)

      match =
        all_petition_pages
        |> Enum.filter(&(&1["name"] == slug))
        |> List.first()

      case match do
        ~m(name) ->
          name

        nil ->
          %{body: ~m(name)} = Ak.Api.post("petitionpage", body: %{name: slug})
          name
      end
    end
  end

  # Info can have ~m(email phone source) as well as pretty standard address
  # attributes. A full list can be found here:
  # https://go.justicedemocrats.com/docs/manual/api/rest/actionprocessing.html?highlight=source#required-arguments
  def process_petition_sign(petition_slug, info) do
    name = name_for_petition_with_slug("external-" <> petition_slug)
    Ak.Api.post("action", body: Map.merge(info, %{page: name}))
  end
end
