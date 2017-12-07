defmodule Ak.List do
  use Agent
  import ShortMaps

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def list_id_of(list) do
    match =
      Ak.Api.stream("list")
      |> Enum.filter(fn ~m(name) -> String.contains?(name, list) end)
      |> List.first()

    case match do
      nil -> nil
      ~m(id) -> id
    end
  end
end
