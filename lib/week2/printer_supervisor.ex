defmodule PrinterSupervisor do
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
            start: {Printer, :start_link, [30]}
          }

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_process(atom) when is_atom(atom) do
    Supervisor.which_children(__MODULE__)
    |> Enum.find(fn {id, _, _, _} -> id == atom end)
    |> elem(1)
  end

  def get_process(int) when is_integer(int) do
    Supervisor.which_children(__MODULE__)
    |> Enum.at(int)
    |> elem(1)
  end
end
