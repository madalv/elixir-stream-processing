{:ok, p} = Printer.start_link(30)

Week1.Statistics.start_link(%{period: 5000, hashtags: %{}})

Week1.Reader.start_link(%{printer_pid: p, url: "http://localhost:4000/tweets/1"})

Week1.Reader.start_link(%{printer_pid: p, url: "http://localhost:4000/tweets/2"})

receive do
  msg -> IO.puts(msg)
end
