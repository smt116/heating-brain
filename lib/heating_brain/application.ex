defmodule HeatingBrain.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      Enum.reject(
        [
          Application.get_env(:heating_brain, :filesystem_process)
          | [
              # The order is important.
              {Collector.Storage, []},
              {Collector.OneWireWorker, []},
              {Collector.HeatingController, []},
              {Collector.Controller, []},
              {Collector.Reader, []},
              {Phoenix.PubSub, [name: InterfaceWeb.PubSub, adapter: Phoenix.PubSub.PG2]},
              InterfaceWeb.Endpoint
            ]
        ],
        &is_nil/1
      )

    opts = [strategy: :rest_for_one, name: HeatingBrain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    InterfaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
