defmodule Reader do
  use GenServer
  require Logger

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def init(url) do
    HTTPoison.get(url, [], recv_timeout: :infinity, stream_to: self())
    {:ok, nil}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, _state) do
    # Printer.print_tweet(chunk)
    Week1.Statistics.analyze_chunk(chunk)
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncStatus{} = status, _state) do
    Logger.debug("Connection status: #{inspect(status)}")
    {:noreply, nil}
  end

  def handle_info(%HTTPoison.AsyncHeaders{} = headers, _state) do
    Logger.debug("Connection headers: #{inspect(headers)}")
    {:noreply, nil}
  end
end
