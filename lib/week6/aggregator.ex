defmodule Week6.Aggregator do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def add_data({id, data}) do
    GenServer.cast(__MODULE__, {:add, id, data})
  end

  def request_next(nr) do
    GenServer.cast(__MODULE__, {:next, nr})
  end

  def handle_cast({:next, nr}, state) do
    list = Enum.filter(state, fn {_, l} -> length(l) == 4 end)

    if length(list) < nr do
      GenServer.cast(__MODULE__, {:next, nr})
      {:noreply, state}
    else
      new_map =
        Enum.reduce(list, state, fn {id, ls}, acc ->
          # Logger.debug("tuple complete #{id} #{inspect(tuple)}")
          Week6.Batcher.add_tweet({id, ls})
          Map.delete(acc, id)
        end)

      {:noreply, new_map}
    end
  end

  def handle_cast({:add, id, data}, state) do
    list =  [data | Map.get(state, id, [])]
    {:noreply, Map.put(state, id, list)}
  end
end
