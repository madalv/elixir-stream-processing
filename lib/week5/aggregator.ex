defmodule Week5.Aggregator do
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

  def handle_cast({:add, id, data}, state) do
    tuple = Map.get(state, id, {}) |> Tuple.append(data)

    if tuple_size(tuple) == 3 do
      Logger.debug("TUPLE COMPLETE: #{inspect(tuple)}")
      Week5.Batcher.add_tweet(%{id => tuple})
      {:noreply, Map.delete(state, id)}
    else
      {:noreply, Map.put(state, id, tuple)}
    end
  end
end
