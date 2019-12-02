defmodule Collector.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # The order of children is important.
    children = [
      {Collector.Storage, []},
      {Collector.HeatingController, []},
      {Collector.Controller, []},
      {Collector.Reader, []}
    ]

    opts = [strategy: :rest_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
