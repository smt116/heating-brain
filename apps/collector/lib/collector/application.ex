defmodule Collector.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Collector.Supervisor]
    Supervisor.start_link([], opts)
  end
end
