Printer.start_link(30)

Reader.start_link("http://localhost:4000/tweets/1")

# Reader.start_link("http://localhost:4000/tweets/2")

Week1.Statistics.start_link(%{period: 5000, hashtags: %{}})

receive do
  msg -> IO.puts(msg)
end
