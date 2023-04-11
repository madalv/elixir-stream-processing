defmodule Week5.Printer do
  alias Week5.Aggregator
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

    {:ok, %{rate_param: rate_param, node: node, lb_pid: lb_pid, swearwords: swearwords}}
  end

  def print_tweet(pid, chunk, node) do
    GenServer.cast(pid, {:print_tweet, chunk, node})
  end

  def get_lb_pid(pid) do
    GenServer.call(pid, :lb)
  end

  def handle_call(:lb, _from, state) do
    {:reply, state[:lb_pid], state}
  end

  def handle_info({:execute, chunk, node}, state) do
    time = Statistics.Distributions.Poisson.rand(state[:rate_param])
    :timer.sleep(round(time))

    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      tweet = data["message"]["tweet"]["text"]
      id = data["message"]["tweet"]["id"]

      redacted = censor_tweet(tweet, state[:swearwords])

      if data["message"]["tweet"]["retweeted_status"] != nil do
        Week5.LoadBalancer.send_retweet(data["message"]["tweet"]["retweeted_status"])
      end

      Logger.info("Received tweet: #{redacted}  \n")
      # Logger.info(inspect(chunk))
      Aggregator.add_data({id, redacted})
    else
      exit(:panic_msg)
    end

    Week5.LoadBalancer.remove_active_conn(state[:lb_pid], node)
    {:noreply, %{state | node: node}}
  end

  def terminate(reason, state) do
    Week5.LoadBalancer.cleanse_conn(state[:lb_pid], state[:node])
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
