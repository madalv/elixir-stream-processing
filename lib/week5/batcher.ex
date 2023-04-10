defmodule Week5.Batcher do
  use GenServer
  require Logger

  def start_link({timeout, batch_size}) do
    GenServer.start_link(__MODULE__, {timeout, batch_size}, name: __MODULE__)
  end

  def init({timeout, batch_size}) do
    Logger.info("Batcher #{inspect(self())} is up.")
    :timer.send_after(timeout, self(), :timeout_print)
    {:ok, %{timeout: timeout, size: batch_size, batch: [], time_expired?: false}}
  end

  def add_tweet(data) do
    GenServer.cast(__MODULE__, {:add, data})
  end

  def handle_cast({:add, data}, state) do
    batch = [data | state[:batch]]

    if length(batch) == state[:size] do
      Logger.info("BATCH FULL #{state[:size]}:")
      Enum.map(batch, fn t -> IO.inspect(t) end)
      {:noreply, %{state | batch: [], time_expired?: false}}
    else
      {:noreply, %{state | batch: batch}}
    end
  end

  def handle_info(:timeout_print, state) do
    if state[:time_expired?] do
      Logger.info("BATCHER TIMEOUT PRINT #{length(state[:batch])}:")
      Enum.map(state[:batch], fn t -> IO.inspect(t) end)
    end

    :timer.send_after(state[:timeout], self(), :timeout_print)
    {:noreply, %{state | time_expired?: true, batch: []}}
  end
end
