defmodule Week4.Printer do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init({rate_param, node, lb_pid}) do
    Process.flag(:trap_exit, true)
    Logger.info("Printer #{inspect(self())} is up.")

    swearwords =
      File.read!("lib/week3/swearwords.json")
      |> Jason.decode!()

    {:ok, {rate_param, node, swearwords, lb_pid}}
  end

  def print_tweet(pid, chunk, node) do
    GenServer.cast(pid, {:print_tweet, chunk, node})
  end

  def get_lb_pid(pid) do
    GenServer.call(pid, :lb)
  end

  def handle_call(:lb, _from, {rate_param, node, swearwords, lb_pid}) do
    {:reply, lb_pid, {rate_param, node, swearwords, lb_pid}}
  end

  def handle_cast({:print_tweet, chunk, node}, {rate_param, _node, swearwords, lb_pid}) do
    time = Statistics.Distributions.Poisson.rand(rate_param)
    :timer.sleep(round(time))

    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    tweet = data["message"]["tweet"]["text"]
    redacted = censor_tweet(tweet, swearwords)

    if success == :ok do
      Logger.info("Received tweet: #{redacted}  \n")
    else
      exit(:panic_msg)
    end

    Week4.GenericLoadBalancer.remove_active_conn(lb_pid, node)
    {:noreply, {rate_param, node, swearwords, lb_pid}}
  end

  def terminate(reason, {_rate_param, node, _swearwords, lb_pid}) do
    Week4.GenericLoadBalancer.cleanse_conn(lb_pid, node)
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
