{:ok, sentiment_sup} = Week4.GenericSupervisor.start_link({3, Week4.SentimentAnalyzer, {}})

{:ok, printer_sup} = Week4.GenericSupervisor.start_link({3, Week4.Printer, {30, 0}})

lb_p = Week4.GenericSupervisor.get_process(0, printer_sup) |> Week4.Printer.get_lb_pid()

lb_s =
  Week4.GenericSupervisor.get_process(0, sentiment_sup) |> Week4.SentimentAnalyzer.get_lb_pid()

Week4.Reader.start_link(%{
  url: "http://localhost:4000/tweets/1",
  printer_lb_pid: lb_p,
  sent_lb_pid: lb_s
})

receive do
  msg -> IO.puts(msg)
end
