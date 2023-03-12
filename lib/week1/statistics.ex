defmodule Week1.Statistics do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    :timer.send_after(state[:period], self(), :print)
    {:ok, state}
  end

  def analyze_chunk(chunk) do
    GenServer.cast(__MODULE__, {:analyze, chunk})
  end

  def handle_cast({:analyze, chunk}, state) do
    map = state[:hashtags]
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      hashtags_data = data["message"]["tweet"]["entities"]["hashtags"]

      cond do
        length(hashtags_data) > 0 ->
          updated =
            Enum.reduce(hashtags_data, map, fn h, acc ->
              hashtag = h["text"]
              cnt = Map.get(state[:hashtags], hashtag, 0) + 1
              Map.put(acc, hashtag, cnt)
            end)

          {:noreply, %{state | hashtags: updated}}

        true ->
          {:noreply, state}
      end
    else
      Logger.warn("Failed to decode message: #{inspect(data)}")
      {:noreply, state}
    end
  end

  def handle_info(:print, state) do
    sorted = Enum.sort(state[:hashtags], fn {_, v1}, {_, v2} -> v1 > v2 end)
    Logger.info("Most popular hashtags in the last 5 seconds are:")
    for i <- 0..4, do: IO.inspect(Enum.at(sorted, i))
    :timer.send_after(state[:period], self(), :print)
    {:noreply, %{state | hashtags: %{}}}
  end
end
