Week3.PrinterSupervisor.start_link(3)

Week3.PoolManager.start_link(3)

Week3.LoadBalancer.start_link(3)

Week3.Reader.start_link(%{url: "http://localhost:4000/tweets/1"})

receive do
  msg -> IO.puts(msg)
end
