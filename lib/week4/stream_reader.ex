defmodule Week4.Reader do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.info("Stream reader #{inspect(self())} is up.")
    HTTPoison.get(state[:url], [], recv_timeout: :infinity, stream_to: self())
    {:ok, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, state) do
    Week4.LoadBalancer.send_chunk(state[:printer_lb_pid], chunk)
    Week4.LoadBalancer.send_chunk(state[:sent_lb_pid], chunk)
    Week4.LoadBalancer.send_chunk(state[:eng_lb_pid], chunk)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{} = status, state) do
    Logger.debug("Connection status: #{inspect(status)}")
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{} = headers, state) do
    Logger.debug("Connection headers: #{inspect(headers)}")
    {:noreply, state}
  end
end
