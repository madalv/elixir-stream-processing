defmodule Week1.Reader do
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
    Printer.print_tweet(state[:printer_pid], chunk)
    # Week1.Statistics.analyze_chunk(chunk)
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
