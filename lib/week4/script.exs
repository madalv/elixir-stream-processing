{:ok, printer_sup} = Week4.GenericSupervisor.start_link({3, Week4.Printer, {30, 0}})

printer0 = Week4.GenericSupervisor.get_process(0, printer_sup)

lb = Week4.Printer.get_lb_pid(printer0)

Week4.Reader.start_link(%{url: "http://localhost:4000/tweets/1", lb_pid: lb})

receive do
  msg -> IO.puts(msg)
end
