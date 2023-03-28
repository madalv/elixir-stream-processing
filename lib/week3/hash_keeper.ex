defmodule Week3.HashKeeper do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("Hash keeper #{inspect(self())} is up.")
    {:ok, state}
  end

  def add_hash(tweet) do
    GenServer.cast(__MODULE__, {:hash, tweet})
  end

  def has_hash?(tweet) do
    GenServer.call(__MODULE__, {:has_hash, tweet})
  end

  def handle_cast({:hash, tweet}, hashmap) do
    hash = :crypto.hash(:md5 , tweet) |> Base.encode16()
    {:noreply, Map.put(hashmap, hash, tweet)}
  end

  def handle_call({:has_hash, tweet}, _from, hashmap) do
    hash = :crypto.hash(:md5 , tweet) |> Base.encode16()
    {:reply, Map.has_key?(hashmap, hash), hashmap}
  end
end
