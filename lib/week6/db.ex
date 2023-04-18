defmodule Week6.Db do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def is_available() do
    :rand.uniform(2) == 2
  end

  def init(_) do
    users = :ets.new(:users, [:set, :public, :named_table])
    tweets = :ets.new(:tweets, [:set, :public, :named_table])
    Logger.debug("DB agent is up.")
    {:ok, {users, tweets}}
  end

  def insert_user(id, username, score) do
    GenServer.cast(__MODULE__, {:insert_user, id, username, score})
  end

  def insert_tweet(id, eng_score, sent_score, tweet, user_id) do
    GenServer.cast(__MODULE__, {:insert_tweet, id, eng_score, sent_score, tweet, user_id})
  end

  def handle_cast({:insert_user, id, username, score}, {users, tweets}) do
    :ets.insert(users, {id, %{user: username, eng_score: score}})

    # Logger.info(inspect(:ets.tab2list(users)))
    {:noreply, {users, tweets}}
  end

  def handle_cast({:insert_tweet, id, eng_score, sent_score, tweet, user_id}, {users, tweets}) do
    :ets.insert(
      tweets,
      {id, %{user_id: user_id, eng_score: eng_score, sent_score: sent_score, text: tweet}}
    )

    # Logger.info(inspect(:ets.tab2list(tweets)))
    {:noreply, {users, tweets}}
  end
end
