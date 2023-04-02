defmodule Week4.PoolManager do
  use GenServer
  require Logger

  # def start_link({min_nodes, req_bound_up, req_bound_down, sup_pid, module}) do
  #   GenServer.start_link(__MODULE__, {min_nodes, req_bound_up, req_bound_down, sup_pid})
  # end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info("Pool manager #{inspect(self())} is up.")
    {:ok, state}
  end

  def trigger_pool_inc(pid) do
    GenServer.cast(pid, {:increase})
  end

  def trigger_pool_dec(pid) do
    GenServer.cast(pid, {:decrease})
  end

  def check_avg(pid, avg) do
    GenServer.cast(pid, {:check_avg, avg})
  end

  def handle_cast({:check_avg, avg}, state) do
    cond do
      avg >= state[:req_bound_up] ->
        trigger_pool_inc(self())
        Logger.warn("Avg #{avg}, gotta raise up the nr")

      avg <= state[:req_bound_down] ->
        trigger_pool_dec(self())
        Logger.warn("Avg #{avg}, gotta cut down the nr")

      true ->
        Logger.warn("Avg #{avg}, everything is chill")
    end

    {:noreply, state}
  end

  def handle_cast({:increase}, state) do
    Week4.GenericSupervisor.add_worker(state[:sup_pid], state[:module], state[:lb_pid])
    {:noreply, state}
  end

  def handle_cast({:decrease}, state) do
    nr = Week4.GenericSupervisor.get_workers_len(state[:sup_pid])

    if nr > state[:min_nodes],
      do:
        Week4.GenericSupervisor.remove_last_worker(
          state[:sup_pid],
          state[:module],
          state[:lb_pid]
        )

    {:noreply, state}
  end
end
