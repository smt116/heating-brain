defmodule Collector.Application do
  @moduledoc false

  use Application

  @handler Application.get_env(:collector, :filesystem_handler)
  @start_mock @handler === Collector.FilesystemMock

  @impl true
  def start(_type, _args) do
    development_children =
      if @start_mock do
        [{Collector.FilesystemMock, []}]
      else
        []
      end

    # The order of children is important.
    children = Enum.concat(
      development_children,
      [
        {Collector.Storage, []},
        {Collector.HeatingController, []},
        {Collector.Controller, []},
        {Collector.Reader, []}
      ]
    )

    opts = [strategy: :rest_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
