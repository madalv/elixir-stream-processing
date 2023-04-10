Week5.Aggregator.start_link([])

{:ok, sentiment_sup} = Week5.GenericSupervisor.start_link({3, Week5.SentimentAnalyzer, {}})

{:ok, printer_sup} = Week5.GenericSupervisor.start_link({3, Week5.Printer, {30, 0}})

{:ok, eng_sup} = Week5.GenericSupervisor.start_link({3, Week5.EngagementAnalyzer, {}})

Week5.Batcher.start_link({300, 20})

lb_p = Week5.GenericSupervisor.get_process(0, printer_sup) |> Week5.Printer.get_lb_pid()

lb_s =
  Week5.GenericSupervisor.get_process(0, sentiment_sup) |> Week5.SentimentAnalyzer.get_lb_pid()

lb_e = Week5.GenericSupervisor.get_process(0, eng_sup) |> Week5.EngagementAnalyzer.get_lb_pid()

Week5.UserEngagement.start_link([])

Week5.Reader.start_link(%{
  url: "http://localhost:4000/tweets/1",
  printer_lb_pid: lb_p,
  sent_lb_pid: lb_s,
  eng_lb_pid: lb_e
})

receive do
  msg -> IO.puts(msg)
end
