defmodule Week3.PrinterSupervisor do
  use Supervisor
  require Logger

  def start_link(nr) do
    Supervisor.start_link(__MODULE__, nr, name: __MODULE__)
  end

  def init(nr) do
    Process.flag(:trap_exit, true)

    children =
      for i <- 1..nr,
          do: %{
            id: String.to_atom("printer#{i}"),
            start: {Week3.Printer, :start_link, [{15, 0}]}
          }

    # max restarts / max seconds needed for the parent not to die of depression :))
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 2_000_000, max_seconds: 5)
  end

  def get_process(atom) when is_atom(atom) do
    Supervisor.which_children(__MODULE__)
    |> Enum.find(fn {id, _, _, _} -> id == atom end)
    |> elem(1)
  end

  def get_process(int) when is_integer(int) do
    Supervisor.which_children(__MODULE__)
    |> Enum.at(int - 1)
    |> elem(1)
  end

  def add_worker() do
    nr = get_workers_len() + 1

    Supervisor.start_child(__MODULE__, %{
      id: String.to_atom("printer#{nr}"),
      start: {Week3.Printer, :start_link, [{30, 0}]}
    })

    Week3.LoadBalancer.add_new_node(nr)

    Logger.debug("Added new child #{nr} #{inspect(Supervisor.which_children(__MODULE__))}")
  end

  def remove_last_worker() do
    nr = get_workers_len()
    Supervisor.terminate_child(__MODULE__, String.to_atom("printer#{nr}"))
    Supervisor.delete_child(__MODULE__, String.to_atom("printer#{nr}"))
    Week3.LoadBalancer.remove_node(nr)
    Logger.debug("Removed new child #{nr} #{inspect(Supervisor.which_children(__MODULE__))}")
  end

  def get_workers_len() do
    length(Supervisor.which_children(__MODULE__))
  end
end
