defmodule Collector.Application do
  @moduledoc false

  use Application

  @handler_process Application.get_env(:collector, :filesystem_process)

  @impl true
  def start(_type, _args) do
    # The order of children is important.
    children = Enum.reject([@handler_process |
                [
                  {Collector.Storage, []},
                  {Collector.HeatingController, []},
                  {Collector.Controller, []},
                  {Collector.Reader, []}
                ]
               ], &is_nil/1)

    opts = [strategy: :rest_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
