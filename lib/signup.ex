defmodule Ak.Signup do
  use Agent
  import ShortMaps

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # Scrapes available signup pages, return the action attribute for the one
  # matching &func/1, which is passed a map with a title attribute
  # like Signup: John Heenan
  def name_for_page_matching(func) do
    existing_match =
      Agent.get(__MODULE__, fn list ->
        matches = Enum.filter(list, fn page -> func.(page) end) |> List.first()
      end)

    if existing_match != nil do
      existing_match["name"]
    else
      all_signup_pages = Ak.Api.stream("signuppage") |> Enum.to_list()
      Agent.update(__MODULE__, fn _ -> all_signup_pages end)

      match =
        all_signup_pages
        |> Enum.filter(fn page -> func.(page) end)
        |> List.first()

      match["name"]
    end
  end

  # Info can have ~m(email phone source) as well as pretty standard address
  # attributes. A full list can be found here:
  # https://go.justicedemocrats.com/docs/manual/api/rest/actionprocessing.html?highlight=source#required-arguments
  def process_signup(candidate, info) do
    name = name_for_page_matching(fn ~m(title) -> String.contains?(title, candidate) and String.contains?(title, "Signup:") end)
    Ak.Api.post("action", body: Map.merge(info, %{page: name}))
  end
end
