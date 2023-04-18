defmodule Week6.EngagementAnalyzer do
  alias Week6.Aggregator
  use GenServer
  require Logger

  def start_link({lb_pid}) do
    GenServer.start_link(__MODULE__, {lb_pid})
  end

  def init({lb_pid}) do
    Process.flag(:trap_exit, true)
    Logger.info("Engagement analyzer #{inspect(self())} is up.")

    {:ok, %{lb_pid: lb_pid, node: 0}}
  end

  def handle_info({:execute, chunk, node}, state) do
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      tweet = data["message"]["tweet"]

      favorites = extract_fav(tweet)
      retweets = extract_retweets(tweet)
      followers = extract_followers(tweet)
      name = extract_name(tweet)

      score = favorites + retweets / followers

      send_user_ratio(tweet["user"]["id"], name, score)

      # Logger.info(
      #   "ENG SCORE: fav #{favorites} | ret #{retweets} | fol  #{followers} | score #{score}  \n #{tweet["text"]}"
      # )
      Aggregator.add_data({tweet["id"], score})
      Aggregator.add_data({tweet["id"], tweet["user"]["id"]})
    else
      exit(:panic_msg)
    end

    Week6.LoadBalancer.remove_active_conn(state[:lb_pid], node)
    {:noreply, %{state | node: node}}
  end

  def get_lb_pid(pid) do
    GenServer.call(pid, :lb)
  end

  def handle_call(:lb, _from, state) do
    {:reply, state[:lb_pid], state}
  end

  def terminate(reason, state) do
    Week6.LoadBalancer.cleanse_conn(state[:lb_pid], state[:node])
    Logger.error("Engagement analyzer #{inspect(self())} going down, reason: #{inspect(reason)}")
  end

  defp extract_fav(tweet) do
    favorites1 = tweet["retweeted_status"]["favorite_count"]

    if favorites1 == nil do
      tweet["favorite_count"]
    else
      favorites1
    end
  end

  defp extract_retweets(tweet) do
    retweets1 = tweet["retweeted_status"]["retweet_count"]

    if retweets1 == nil do
      tweet["retweet_count"]
    else
      retweets1
    end
  end

  defp extract_followers(tweet) do
    tweet["user"]["followers_count"]
  end

  defp extract_name(tweet) do
    tweet["user"]["name"]
  end

  defp send_user_ratio(id, username, ratio) do
    Week6.UserEngagement.add_ratio(id, username, ratio)
  end
end
