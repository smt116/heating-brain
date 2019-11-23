defmodule Collector.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    :ok = Collector.Storage.init()

    children = [
      {Collector.Reader, []}
    ]

    opts = [strategy: :one_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
