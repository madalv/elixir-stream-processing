Week6.Aggregator.start_link([])

Week6.Db.start_link(nil)

{:ok, sentiment_sup} = Week6.GenericSupervisor.start_link({3, Week6.SentimentAnalyzer, {}})

{:ok, printer_sup} = Week6.GenericSupervisor.start_link({3, Week6.Printer, {30, 0}})

{:ok, eng_sup} = Week6.GenericSupervisor.start_link({3, Week6.EngagementAnalyzer, {}})

Week6.Batcher.start_link({300, 30})

lb_p = Week6.GenericSupervisor.get_process(0, printer_sup) |> Week6.Printer.get_lb_pid()

lb_s =
  Week6.GenericSupervisor.get_process(0, sentiment_sup) |> Week6.SentimentAnalyzer.get_lb_pid()

lb_e = Week6.GenericSupervisor.get_process(0, eng_sup) |> Week6.EngagementAnalyzer.get_lb_pid()

Week6.UserEngagement.start_link([])

Week6.Reader.start_link(%{
  url: "http://localhost:4000/tweets/1",
  printer_lb_pid: lb_p,
  sent_lb_pid: lb_s,
  eng_lb_pid: lb_e
})

receive do
  msg -> IO.puts(msg)
end
