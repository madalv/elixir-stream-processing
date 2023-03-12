defmodule Printer do
  use GenServer
  require Logger

  def start_link(rate_param) do
    GenServer.start_link(__MODULE__, rate_param, name: __MODULE__)
  end

  def init(rate_param) do
    {:ok, rate_param}
  end

  def print_tweet(chunk) do
    GenServer.cast(__MODULE__, {:print_tweet, chunk})
  end

  def handle_cast({:print_tweet, chunk}, rate_param) do
    :timer.sleep(round(Statistics.Distributions.Poisson.rand(rate_param)))

    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      Logger.info("Received tweet: #{inspect(data["message"]["tweet"]["text"])} \n")
    else
      Logger.warn("Failed to decode message: #{inspect(data)}")
    end

    {:noreply, rate_param}
  end
end
