defmodule Week4.GenericSupervisor do
  use Supervisor
  require Logger

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state)
  end

  def init({nr, module, init_state}) do
    Process.flag(:trap_exit, true)

    {:ok, lb} = Week4.GenericLoadBalancer.start_link({nr, self()})

    {:ok, printer_manager} = Week4.PoolManager.start_link(%{
      min_nodes: 3,
      req_bound_up: 40,
      req_bound_down: 30,
      sup_pid: self(),
      lb_pid: lb,
      module: Week4.Printer})

      Week4.GenericLoadBalancer.add_pool_manager_pid(lb, printer_manager)

    children =
      for i <- 1..nr,
          do: %{
            id: String.to_atom("#{module}#{i}"),
            start: {module, :start_link, [Tuple.append(init_state, lb)]}
          }

    # max restarts / max seconds needed for the parent not to die of depression :))
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 2_000_000, max_seconds: 5)
  end

  def get_process(atom, pid) when is_atom(atom) do
    Supervisor.which_children(pid)
    |> Enum.find(fn {id, _, _, _} -> id == atom end)
    |> elem(1)
  end

  def get_process(int, pid) when is_integer(int) do
    Supervisor.which_children(pid)
    |> Enum.at(int - 1)
    |> elem(1)
  end

  def add_worker(pid, module, lb_pid) do
    nr = get_workers_len(pid) + 1

    Supervisor.start_child(pid, %{
      id: String.to_atom("#{module}#{nr}"),
      start: {module, :start_link, [{30, 0, lb_pid}]}
    })

    Week4.GenericLoadBalancer.add_new_node(lb_pid, nr)

    Logger.debug("Added new child #{nr} #{inspect(Supervisor.which_children(pid))}")
  end

  def remove_last_worker(pid, lb_pid) do
    nr = get_workers_len(pid)
    Supervisor.terminate_child(pid, String.to_atom("printer#{nr}"))
    Supervisor.delete_child(pid, String.to_atom("printer#{nr}"))
    Week4.GenericLoadBalancer.remove_node(lb_pid, nr)
    Logger.debug("Removed new child #{nr} #{inspect(Supervisor.which_children(pid))}")
  end

  def get_workers_len(pid) do
    length(Supervisor.which_children(pid))
  end
end
