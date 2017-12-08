defmodule Ak.Signup do
  use Agent
  import ShortMaps

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  # Scrapes available signup pages, return the one matching &func/1, which is
  # passed a map with a title attribute like Signup: John Heenan
  def page_matching(func) do
    existing_match =
      Agent.get(__MODULE__, fn list ->
        matches = Enum.filter(list, fn page -> func.(page) end) |> List.first()
      end)

    if existing_match != nil do
      existing_match
    else
      all_signup_pages = Ak.Api.stream("signuppage") |> Enum.to_list()
      Agent.update(__MODULE__, fn _ -> all_signup_pages end)

      match =
        all_signup_pages
        |> Enum.filter(fn page -> func.(page) end)
        |> List.first()

      match
    end
  end

  def name_for_page_matching(func) do
    match = page_matching(func)
    match["name"]
  end

  # Info can have ~m(email phone source) as well as pretty standard address
  # attributes. A full list can be found here:
  # https://go.justicedemocrats.com/docs/manual/api/rest/actionprocessing.html?highlight=source#required-arguments
  def process_signup(list_partial, info) when is_string(list_partial) do
    name = name_for_page_matching(fn ~m(title) -> String.contains?(title, list_partial) and String.contains?(title, "Signup:") end)
    Ak.Api.post("action", body: Map.merge(info, %{page: name}))
  end

  def process_signup(matching_func, info) when is_function(matching_func) do
    name = name_for_page_matching(matching_func)
    Ak.Api.post("action", body: Map.merge(info, %{page: name}))
  end
end
