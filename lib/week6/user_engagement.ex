defmodule Week6.UserEngagement do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_) do
    Logger.info("User engagement analyzer #{inspect(self())} is up.")
    {:ok, %{users: %{}}}
  end

  def add_ratio(id, username, ratio) do
    GenServer.cast(__MODULE__, {:ratio, id, username, ratio})
  end

  def handle_cast({:ratio, id, username, ratio}, state) do
    val = Map.get(state[:users], id, {0, 0}) |> elem(1)
    new_state = Map.put(state[:users], id, {username, val + ratio})

    # Logger.debug(
    #   "USER RATIO | #{id} #{username} #{ratio} => #{val + ratio} |  #{Kernel.map_size(state[:users])}"
    # )

    persist(id, username, ratio)

    {:noreply, %{users: new_state}}
  end

  defp persist(id, username, ratio) do
    if Process.whereis(Week6.Db) != nil and
         Process.alive?(Process.whereis(Week6.Db)) do
      Week6.Db.insert_user(id, username, ratio)
      Logger.info("Persisted user.")
    else
      :timer.sleep(10)
      Logger.error("Could not persist user, try again in 10 ms.")
      persist(id, username, ratio)
    end
  end
end
