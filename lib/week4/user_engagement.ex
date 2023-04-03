defmodule Week4.UserEngagement do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    Logger.info("User engagement analyzer #{inspect(self())} is up.")
    {:ok, %{users: %{}}}
  end

  def add_ratio(username, ratio) do
    GenServer.cast(__MODULE__, {:ratio, username, ratio})
  end

  def handle_cast({:ratio, username, ratio}, state) do

    val = Map.get(state[:users], username, 0)
    new_state = Map.put(state[:users], username, val + ratio)

    Logger.debug("USER RATIO | #{username} #{ratio} => #{val + ratio} | nr users #{Kernel.map_size(state[:users])}")

    {:noreply, %{users: new_state}}
  end

end
