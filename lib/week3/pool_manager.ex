defmodule Week3.PoolManager do
  use GenServer
  require Logger

  def start_link(min_nodes) do
    GenServer.start_link(__MODULE__, min_nodes, name: __MODULE__)
  end

  def init(min_nodes) do
    Logger.info("Pool manager #{inspect(self())} is up.")
    {:ok, min_nodes}
  end

  def trigger_pool_inc() do
    GenServer.cast(__MODULE__, {:increase})
  end

  def trigger_pool_dec() do
    GenServer.cast(__MODULE__, {:decrease})
  end

  def handle_cast({:increase}, state) do
    Week3.PrinterSupervisor.add_worker()
    {:noreply, state}
  end

  def handle_cast({:decrease}, min_nodes) do
    nr = Week3.PrinterSupervisor.get_workers_len()

    if nr > min_nodes, do: Week3.PrinterSupervisor.remove_last_worker()
    {:noreply, min_nodes}
  end
end
