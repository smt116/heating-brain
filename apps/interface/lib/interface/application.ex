defmodule Interface.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      InterfaceWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Interface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    InterfaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
