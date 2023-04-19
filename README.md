# Lab 2 PTR (Stream Processing)
 
A tweet processing system written in Elixir. Eeach week is a version of the system,
with Week 1 being the initial version and Week 6 the final one. Each week inbetween 
is an intermediate week that shows the progress of the system (based on the tasks for each week.)

Check out `diagrams/report.md` for a way more detailed explanation of the tasks and implementation.

## Docker Container

First things first, download the [Docker image](https://hub.docker.com/layers/alexburlacu/rtp-server/faf18x/images/sha256-24f504eab5a4dbb504382eaf15d78bb0679c3178f848041b7e2cd33727f0d086?context=explore) (IMPORTANT: you need image with the `faf18x` tag!)

Then start the container:

```bash
docker run -p 4000:4000 alexburlacu/rtp-server:faf18x
```

## Starting the Project

Each week has a script. 
To run the tasks for a particular week, change into the root folder and execute:

```bash
mix run lib/week6/script.exs
```

This will execute the final version of the project (make sure the Docker container is up and running).

Alternatively, to start Elixir's interactive shell loaded with the project execute (from the root folder):

```bash
iex -S mix
```

## Formatting

To format, execute:

```bash
mix format
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `streamp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:streamp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/streamp](https://hexdocs.pm/streamp).

