defmodule Week6.LoadBalancer do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init({nr_nodes, printer_sup, module}) do
    Logger.info("Load balancer #{inspect(self())} is up.")
    :timer.send_after(500, self(), :send_avg)
    nodes = for i <- 1..nr_nodes, into: %{}, do: {i, 0}

    Logger.debug(inspect(nodes))

    {:ok,
     %{
       nr_nodes: nr_nodes,
       msg_nr: 0,
       nodes: nodes,
       avg: 0,
       sup_pid: printer_sup,
       manager_pid: "tobeadded",
       module: module
     }}
  end

  def add_pool_manager_pid(pid, manager) do
    GenServer.cast(pid, {:manager_add, manager})
  end

  def send_chunk(pid, chunk) do
    GenServer.cast(pid, {:send, chunk})
  end

  def remove_active_conn(pid, node) do
    GenServer.cast(pid, {:rm_active_conn, node})
  end

  def add_new_node(pid, nr) do
    GenServer.cast(pid, {:new_node, nr})
  end

  def remove_node(pid, nr) do
    GenServer.cast(pid, {:rm_node, nr})
  end

  def handle_cast({:manager_add, manager}, state) do
    {:noreply, %{state | manager_pid: manager}}
  end

  def handle_cast({:rm_node, nr}, state) do
    new_nodes = Map.delete(state[:nodes], nr)
    {:noreply, %{state | nr_nodes: state[:nr_nodes] - 1, nodes: new_nodes}}
  end

  def handle_cast({:new_node, nr}, state) do
    new_nodes = Map.put(state[:nodes], nr, 0)
    {:noreply, %{state | nr_nodes: state[:nr_nodes] + 1, nodes: new_nodes}}
  end

  def cleanse_conn(pid, node) do
    GenServer.cast(pid, {:cleanse_conn, node})
  end

  def handle_info(:send_avg, state) do
    Week6.PoolManager.check_avg(state[:manager_pid], state[:avg])
    :timer.send_after(500, self(), :send_avg)

    {:noreply, state}
  end

  def get_avg_requests(pid) do
    GenServer.call(pid, {:avg})
  end

  def handle_call({:avg}, _from, state) do
    {:reply, state[:avg], state}
  end

  def handle_cast({:cleanse_conn, node}, state) do
    nodes = Map.put(state[:nodes], node, 0)

    # Logger.warn("Worker #{inspect(state[:module])} #{node} is down/restarted; #{inspect(nodes)}")
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
      # Logger.debug("Worker #{inspect(state[:module])} #{node} is done; #{inspect(nodes)}")
      {:noreply, %{state | nodes: nodes}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:send, chunk}, state) do
    node = state[:nodes] |> Enum.sort(fn {_, v1}, {_, v2} -> v1 < v2 end) |> Enum.at(0) |> elem(0)

    sum = Enum.reduce(state[:nodes], 0, fn {_, v}, acc -> acc + v end)
    avg = sum / map_size(state[:nodes])

    worker = Week6.GenericSupervisor.get_process(node, state[:sup_pid])
    nodes = Map.put(state[:nodes], node, state[:nodes][node] + 1)

    Logger.info("Node #{inspect(state[:module])} nr: #{node}, sent to #{inspect(worker)}")

    Process.send(worker, {:execute, chunk, node}, [])

    {:noreply, %{state | msg_nr: state[:msg_nr] + 1, nodes: nodes, avg: avg}}
  end

  def send_retweet(retweeted_status) do
    chunk =
      "event: \"message\"\n\ndata: {\"message\": {\"tweet\":" <>
        Jason.encode!(retweeted_status) <>
        "}}"

    # Logger.info("Sending retweet: #{retweeted_status["text"]}")

    send(Week6.Reader, %HTTPoison.AsyncChunk{chunk: chunk})
  end
end
