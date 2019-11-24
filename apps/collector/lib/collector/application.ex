defmodule Collector.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Collector.Reader, []},
      {Collector.Storage, []}
    ]

    opts = [strategy: :one_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
