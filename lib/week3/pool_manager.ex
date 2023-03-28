defmodule Week3.PoolManager do
  use GenServer
  require Logger

  def start_link({min_nodes, req_bound_up, req_bound_down}) do
    GenServer.start_link(__MODULE__, {min_nodes, req_bound_up, req_bound_down}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("Pool manager #{inspect(self())} is up.")
    {:ok, state}
  end

  def trigger_pool_inc() do
    GenServer.cast(__MODULE__, {:increase})
  end

  def trigger_pool_dec() do
    GenServer.cast(__MODULE__, {:decrease})
  end

  def check_avg(avg) do
    GenServer.cast(__MODULE__, {:check_avg, avg})
  end

  def handle_cast({:check_avg, avg}, {min_nodes, req_bound_up, req_bound_down}) do
    cond do
      avg >= req_bound_up ->
        trigger_pool_inc()
        Logger.warn("Avg #{avg}, gotta raise up the nr")

      avg <= req_bound_down ->
        trigger_pool_dec()
        Logger.warn("Avg #{avg}, gotta cut down the nr")

      true ->
        Logger.warn("Avg #{avg}, everything is chill")
    end

    {:noreply, {min_nodes, req_bound_up, req_bound_down}}
  end

  def handle_cast({:increase}, state) do
    Week3.PrinterSupervisor.add_worker()
    {:noreply, state}
  end

  def handle_cast({:decrease}, {min_nodes, req_bound_up, req_bound_down}) do
    nr = Week3.PrinterSupervisor.get_workers_len()

    if nr > min_nodes, do: Week3.PrinterSupervisor.remove_last_worker()
    {:noreply, {min_nodes, req_bound_up, req_bound_down}}
  end
end
