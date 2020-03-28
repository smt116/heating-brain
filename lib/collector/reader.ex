defmodule Collector.Reader do
  @moduledoc """
  The process that periodically reads values from sensors and saves them into the
  storage.
  """

  use GenServer

  require Logger

  import Application, only: [get_env: 2]
  import Collector.OneWire, only: [sensors: 0]
  import Collector.OneWireWorker, only: [read: 1]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement

  @opaque state :: []
  @typep id :: Measurement.id()

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    if get_env(:heating_brain, :read_initial_enabled) do
      get_env(:heating_brain, :read_initial_delay) |> schedule_next_read_after()
    end

    {:ok, state}
  end

  @spec start_link(list) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @spec handle_cast({:read, id}, state) :: {:noreply, state}
  def handle_cast({:read, id}, state) do
    id |> read() |> handle_read_result()

    {:noreply, state}
  end

  @impl true
  @spec handle_info(:read_all, state) :: {:noreply, state}
  def handle_info(:read_all, state) do
    sensors() |> Enum.each(&GenServer.cast(__MODULE__, {:read, &1}))
    get_env(:heating_brain, :read_interval) |> schedule_next_read_after()

    {:noreply, state}
  end

  defp handle_read_result({:ok, %Measurement{} = m}), do: write(m)
  defp handle_read_result({:error, msg}), do: Logger.error(fn -> msg end)

  defp schedule_next_read_after(interval) do
    Process.send_after(self(), :read_all, interval)
  end
end
