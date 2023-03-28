defmodule Week3.LoadBalancer do
  use GenServer
  require Logger

  def start_link(nr_nodes) do
    GenServer.start_link(__MODULE__, nr_nodes, name: __MODULE__)
  end

  def init(nr_nodes) do
    Logger.info("Load balancer #{inspect(self())} is up.")
    :timer.send_after(500, self(), :send_avg)
    nodes = for i <- 1..nr_nodes, into: %{}, do: {i, 0}

    Logger.debug(inspect(nodes))
    {:ok, %{nr_nodes: nr_nodes, msg_nr: 0, nodes: nodes, avg: 0}}
  end

  def send_chunk(chunk) do
    GenServer.cast(__MODULE__, {:send, chunk})
  end

  def remove_active_conn(node) do
    GenServer.cast(__MODULE__, {:rm_active_conn, node})
  end

  def add_new_node(nr) do
    GenServer.cast(__MODULE__, {:new_node, nr})
  end

  def remove_node(nr) do
    GenServer.cast(__MODULE__, {:rm_node, nr})
  end

  def handle_cast({:rm_node, nr}, state) do
    new_nodes = Map.delete(state[:nodes], nr)
    {:noreply, %{state | nr_nodes: state[:nr_nodes] - 1, nodes: new_nodes}}
  end

  def handle_cast({:new_node, nr}, state) do
    new_nodes = Map.put(state[:nodes], nr, 0)
    {:noreply, %{state | nr_nodes: state[:nr_nodes] + 1, nodes: new_nodes}}
  end

  def cleanse_conn(node) do
    GenServer.cast(__MODULE__, {:cleanse_conn, node})
  end

  def handle_info(:send_avg, state) do
    Week3.PoolManager.check_avg(state[:avg])
    :timer.send_after(500, self(), :send_avg)

    {:noreply, state}
  end

  def get_avg_requests() do
    GenServer.call(__MODULE__, {:avg})
  end

  def handle_call({:avg}, _from, state) do
    {:reply, state[:avg], state}
  end

  def handle_cast({:cleanse_conn, node}, state) do
    nodes = Map.put(state[:nodes], node, 0)
    Logger.warn("Printer #{node} is down/restarted; #{inspect(nodes)}")
    {:noreply, %{state | nodes: nodes}}
  end

  def handle_cast({:rm_active_conn, node}, state) do
    if Map.has_key?(state[:nodes], node) do
      val =
        if state[:nodes][node] == 0 do
          0
        else
          state[:nodes][node] - 1
        end

      nodes = Map.put(state[:nodes], node, val)
      Logger.debug("Printer #{node} is done; #{inspect(nodes)}")
      {:noreply, %{state | nodes: nodes}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:send, chunk}, state) do
    # node = rem(state[:msg_nr], state[:nr_nodes])

    node = state[:nodes] |> Enum.sort(fn {_, v1}, {_, v2} -> v1 < v2 end) |> Enum.at(0) |> elem(0)

    sum = Enum.reduce(state[:nodes], 0, fn {_, v}, acc -> acc + v end)
    avg = sum / map_size(state[:nodes])

    # Logger.debug(inspect(node))
    # Logger.debug(inspect(state[:nodes]))

    printer = Week3.PrinterSupervisor.get_process(node)
    nodes = Map.put(state[:nodes], node, state[:nodes][node] + 1)

    Logger.info("Node nr: #{node}, sent to #{inspect(printer)}")

    Week2.Printer.print_tweet(printer, chunk, node)

    {:noreply, %{state | msg_nr: state[:msg_nr] + 1, nodes: nodes, avg: avg}}
  end
end
