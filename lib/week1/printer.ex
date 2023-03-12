defmodule Printer do
  use GenServer
  require Logger

  def start_link(rate_param) do
    GenServer.start_link(__MODULE__, rate_param)
  end

  def init(rate_param) do
    Process.flag(:trap_exit, true)
    Logger.info("Printer #{inspect(self())} is up.")
    {:ok, rate_param}
  end

  def print_tweet(pid, chunk) do
    GenServer.cast(pid, {:print_tweet, chunk})
  end

  def handle_cast({:print_tweet, chunk}, rate_param) do
    :timer.sleep(round(Statistics.Distributions.Poisson.rand(rate_param)))

    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      Logger.info("Received tweet: #{inspect(data["message"]["tweet"]["text"])} \n")
    else
      exit(:panic_msg)
    end

    {:noreply, rate_param}
  end

  def terminate(reason, _state) do
    Logger.error("Printer #{inspect(self())} going down, reason: #{inspect(reason)}")
  end
end
