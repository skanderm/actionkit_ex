defmodule Ak.Petition do
  use Agent
  import ShortMaps

  @default_list 1

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # Scrapes available petition pages, return the action attribute for the one
  # matching &func/1, which is passed a map with a title attribute
  # like Signup: John Heenan
  def name_for_petition_with_slug(slug, list_partial \\ false) do
    existing_match =
      Agent.get(__MODULE__, fn list ->
        matches = Enum.filter(list, &(&1["name"] == slug)) |> List.first()
      end)

    if existing_match != nil do
      existing_match["name"]
    else
      all_petition_pages = Ak.Api.stream("petitionpage") |> Enum.to_list()
      Agent.update(__MODULE__, fn _ -> all_petition_pages end)

      match =
        all_petition_pages
        |> Enum.filter(&(&1["name"] == slug))
        |> List.first()

      case match do
        ~m(name) ->
          name

        nil ->
          list = if list_partial, do: Ak.List.list_id_of(list_partial), else: @default_list
          %{body: body} = Ak.Api.post("petitionpage", body: %{name: slug, list: "/rest/v1/list/#{list}/"})
          name_for_petition_with_slug(slug, list_partial)
      end
    end
  end

  # Info can have ~m(email phone source) as well as pretty standard address
  # attributes. A full list can be found here:
  # https://go.justicedemocrats.com/docs/manual/api/rest/actionprocessing.html?highlight=source#required-arguments
  def process_petition_sign(petition_slug, info, list_partial \\ false) do
    slug = if list_partial, do: slugize(list_partial) <> petition_slug, else: petition_slug
    name = name_for_petition_with_slug("external-" <> slug)
    Ak.Api.post("action", body: Map.merge(info, %{page: name}))
  end

  defp slugize(name) do
    String.downcase(name)
    |> String.replace(" ", "-")
  end
end
