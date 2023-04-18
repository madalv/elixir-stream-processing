defmodule Week6.Batcher do
  alias Week6.Aggregator
  use GenServer
  require Logger

  def start_link({timeout, batch_size}) do
    GenServer.start_link(__MODULE__, {timeout, batch_size}, name: __MODULE__)
  end

  def init({timeout, batch_size}) do
    Logger.info("Batcher #{inspect(self())} is up.")
    :timer.send_after(timeout, self(), :timeout_print)
    Aggregator.request_next(1)
    {:ok, %{timeout: timeout, size: batch_size, batch: [], time_expired?: false}}
  end

  def add_tweet(data) do
    GenServer.cast(__MODULE__, {:add, data})
  end

  def handle_cast({:add, data}, state) do
    batch = [data | state[:batch]]

    len = elem(Process.info(self(), :message_queue_len), 1)

    Logger.info("Batcher queue: #{len}")

    if len == 0, do: Week6.Aggregator.request_next(1)

    if length(batch) == state[:size] do
      # Logger.info("BATCH FULL #{state[:size]}:")

      Enum.map(batch, fn {id, ls} -> persist(id, ls) end)
      {:noreply, %{state | batch: [], time_expired?: false}}
    else
      {:noreply, %{state | batch: batch}}
    end
  end

  def handle_info(:timeout_print, state) do
    if state[:time_expired?] do
      # Logger.info("BATCH TIMEOUT PRINT #{length(state[:batch])}:")
      Enum.map(state[:batch], fn {id, ls} -> persist(id, ls) end)
    end

    :timer.send_after(state[:timeout], self(), :timeout_print)
    {:noreply, %{state | time_expired?: true, batch: []}}
  end

  defp persist(id, tweet) do
    if Process.whereis(Week6.Db) != nil and
         Process.alive?(Process.whereis(Week6.Db)) do
      [sent, eng, user, string] = Enum.sort(tweet)
      Week6.Db.insert_tweet(id, eng, sent, string, user)
      Logger.info("Persisted tweet.")
    else
      Logger.error("Could not persist tweet, try again in 10 ms.")
      :timer.sleep(10)
      persist(id, tweet)
    end
  end
end
