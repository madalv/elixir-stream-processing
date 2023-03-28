defmodule Week3.Printer do
  use GenServer
  require Logger

  def start_link({rate_param, node}) do
    GenServer.start_link(__MODULE__, {rate_param, node})
  end

  def init({rate_param, node}) do
    Process.flag(:trap_exit, true)
    Logger.info("Printer #{inspect(self())} is up.")

    swearwords =
      File.read!("lib/week3/swearwords.json")
      |> Jason.decode!()

    {:ok, {rate_param, node, swearwords}}
  end

  def print_tweet(pid, chunk, node) do
    GenServer.cast(pid, {:print_tweet, chunk, node})
  end

  def handle_cast({:print_tweet, chunk, node}, {rate_param, _node, swearwords}) do
    time = Statistics.Distributions.Poisson.rand(rate_param)
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    tweet = data["message"]["tweet"]["text"]
    redacted = censor_tweet(tweet, swearwords)

    if success == :ok do
      if !Week3.HashKeeper.has_hash?(tweet) do
        Week3.HashKeeper.add_hash(tweet)
        :timer.sleep(round(time))
        Logger.info("Received tweet: #{redacted}  \n")
      end
    else
      exit(:panic_msg)
    end

    Week3.LoadBalancer.remove_active_conn(node)
    {:noreply, {rate_param, node, swearwords}}
  end

  def terminate(reason, {_rate_param, node, _swearwords}) do
    Week3.LoadBalancer.cleanse_conn(node)
    Logger.error("Printer #{inspect(self())} going down, reason: #{inspect(reason)}")
  end

  def censor_tweet(tweet, swearwords) do
    tweet
    |> String.split(" ", trim: true)
    |> Enum.map(fn word ->
      w = String.downcase(word)

      if w in swearwords do
        String.duplicate("*", String.length(w))
      else
        w
      end
    end)
    |> Enum.join(" ")
  end
end
