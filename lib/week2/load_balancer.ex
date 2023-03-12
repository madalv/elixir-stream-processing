defmodule LoadBalancer do
  use GenServer
  require Logger

  def start_link(nr_nodes) do
    GenServer.start_link(__MODULE__, nr_nodes, name: __MODULE__)
  end

  def init(nr_nodes) do
    Logger.info("Load balancer #{inspect(self())} is up.")
    {:ok, %{nr_nodes: nr_nodes, msg_nr: 0}}
  end

  def send_chunk(chunk) do
    GenServer.cast(__MODULE__, {:send, chunk})
  end

  def handle_cast({:send, chunk}, state) do
    node = rem(state[:msg_nr], state[:nr_nodes])
    printer = PrinterSupervisor.get_process(node)
    # Logger.info("Node nr: #{node}, sent to #{inspect(printer)}")
    Printer.print_tweet(printer, chunk)

    {:noreply, %{state | msg_nr: state[:msg_nr] + 1}}
  end
end
