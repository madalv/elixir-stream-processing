defmodule Week5.SentimentAnalyzer do
  alias Week5.Aggregator
  use GenServer
  require Logger

  def start_link({lb_pid}) do
    GenServer.start_link(__MODULE__, {lb_pid})
  end

  def init({lb_pid}) do
    Process.flag(:trap_exit, true)
    Logger.info("Sentiment analyzer #{inspect(self())} is up.")

    response = HTTPoison.get!("http://localhost:4000/emotion_values")

    map = response.body |> parse()

    {:ok, %{emotion: map, lb_pid: lb_pid, node: 0}}
  end

  def handle_info({:execute, chunk, node}, state) do
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, data} = Jason.decode(String.trim(message))

    if success == :ok do
      tweet = data["message"]["tweet"]["text"]
      split = tweet |> String.split(" ", trim: true)

      nr = length(split)

      score =
        split
        |> Enum.reduce(0, fn w, acc ->
          score = Map.get(state[:emotion], w, 0)
          acc + score
        end)

      # Logger.info("#{inspect(tweet)} \n SCORE: #{score / nr}")
      Aggregator.add_data({data["message"]["tweet"]["id"], score})
    else
      exit(:panic_msg)
    end

    Week5.LoadBalancer.remove_active_conn(state[:lb_pid], node)
    {:noreply, %{state | node: node}}
  end

  def get_lb_pid(pid) do
    GenServer.call(pid, :lb)
  end

  def handle_call(:lb, _from, state) do
    {:reply, state[:lb_pid], state}
  end

  defp parse(text) do
    text
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      words = String.split(line, ~r/\s+/, trim: true)
      value = String.to_integer(List.last(words))
      key = Enum.join(List.delete_at(words, -1), " ")
      Map.put(acc, key, value)
    end)
  end

  def terminate(reason, state) do
    Week5.LoadBalancer.cleanse_conn(state[:lb_pid], state[:node])
    Logger.error("Sentiment analyzer #{inspect(self())} going down, reason: #{inspect(reason)}")
  end
end
