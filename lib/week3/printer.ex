defmodule Week3.Printer do
  use GenServer
  require Logger

  def start_link({rate_param, node}) do
    GenServer.start_link(__MODULE__, {rate_param, node})
  end

  def init({rate_param, node}) do
    Process.flag(:trap_exit, true)
    Logger.info("Printer #{inspect(self())} is up.")
    {:ok, {rate_param, node}}
  end

  def print_tweet(pid, chunk, node) do
    GenServer.cast(pid, {:print_tweet, chunk, node})
  end

  def handle_cast({:print_tweet, chunk, node}, {rate_param, _node}) do
    time = Statistics.Distributions.Poisson.rand(rate_param)
    :timer.sleep(round(time))

    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      Logger.info(
        "#{time} Received tweet: #{inspect(data["message"]["tweet"]["text"])} pid #{inspect(self())}  \n"
      )
    else
      exit(:panic_msg)
    end

    Week3.LoadBalancer.remove_active_conn(node)
    {:noreply, {rate_param, node}}
  end

  def terminate(reason, {_rate_param, node}) do
    Week3.LoadBalancer.cleanse_conn(node)
    Logger.error("Printer #{inspect(self())} going down, reason: #{inspect(reason)}")
  end
end
