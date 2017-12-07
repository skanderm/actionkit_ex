defmodule Ak.List do
  use Agent
  import ShortMaps

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def list_id_of(list_partial) do
    existing_match = Agent.get(__MODULE__, fn list ->
      Enum.filter(list, fn ~m(name) -> String.contains?(name, list_partial) end) |> List.first()
    end)

    if existing_match != nil do
      existing_match["id"]
    else
      all_lists = Ak.Api.stream("list") |> Enum.to_list()
      Agent.update(__MODULE__, fn _ -> all_lists end)

      match =
        all_lists
        |> Enum.filter(fn ~m(name) -> String.contains?(name, list_partial) end)
        |> List.first()

      case match do
        nil -> nil
        ~m(id) -> id
      end
    end
  end
end
