defmodule LoadBalancer do
  use GenServer
  require Logger

  def start_link(nr_nodes) do
    GenServer.start_link(__MODULE__, nr_nodes, name: __MODULE__)
  end

  def init(nr_nodes) do
    Logger.info("Load balancer #{inspect(self())} is up.")
    nodes = for i <- 0..(nr_nodes - 1), into: %{}, do: {i, 0}

    Logger.debug(inspect(nodes))
    {:ok, %{nr_nodes: nr_nodes, msg_nr: 0, nodes: nodes}}
  end

  def send_chunk(chunk) do
    GenServer.cast(__MODULE__, {:send, chunk})
  end

  def remove_active_conn(node) do
    GenServer.cast(__MODULE__, {:rm_active_conn, node})
  end

  def handle_cast({:rm_active_conn, node}, state) do
    nodes = Map.put(state[:nodes], node, state[:nodes][node] - 1)
    Logger.debug("Printer #{node} is done; #{inspect(nodes)}")
    {:noreply, %{state | nodes: nodes}}
  end

  def handle_cast({:send, chunk}, state) do
    # node = rem(state[:msg_nr], state[:nr_nodes])

    # Logger.info("Node nr: #{node}, sent to #{inspect(printer)}")

    node = state[:nodes] |> Enum.sort(fn {_, v1}, {_, v2} -> v1 < v2 end) |> Enum.at(0) |> elem(0)

    # Logger.debug(inspect(node))
    # Logger.debug(inspect(state[:nodes]))

    printer = PrinterSupervisor.get_process(node)
    nodes = Map.put(state[:nodes], node, state[:nodes][node] + 1)

    Week2.Printer.print_tweet(printer, chunk, node)

    {:noreply, %{state | msg_nr: state[:msg_nr] + 1, nodes: nodes}}
  end
end
