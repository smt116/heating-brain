defmodule Collector.Reader do
  @moduledoc """
  The process that periodically reads values from sensors and saves them into the
  storage.
  """

  use GenServer

  require Logger

  import Collector.Sensors, only: [read_all: 0]
  import Collector.Storage, only: [write: 1]

  @opaque state :: []

  @read_interval Application.get_env(:collector, :read_interval)
  @read_initial_delay Application.get_env(:collector, :read_initial_delay)

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    if Application.get_env(:collector, :read_initial_enabled) do
      schedule_next_read_after(@read_initial_delay)
    end

    {:ok, state}
  end

  @spec start_link(list) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @spec handle_info(:read_all, state) :: {:noreply, state}
  def handle_info(:read_all, state) do
    Enum.each(read_all(), &write/1)

    schedule_next_read_after(@read_interval)

    {:noreply, state}
  end

  defp schedule_next_read_after(interval) do
    Process.send_after(self(), :read_all, interval)
  end
end
