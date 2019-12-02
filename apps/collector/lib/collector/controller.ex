defmodule Collector.Controller do
  @moduledoc """
  The process that listens to readings from sensors and controls relays.
  """

  use GenServer

  require Logger

  import Collector.Relays, only: [put_state: 1, read_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  @opaque state :: []

  @typep record :: Measurement.t() | RelayState.t()

  @sensors_map Application.get_env(:collector, :sensors_map)

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    Storage.subscribe()

    read_all() |> Enum.each(&write/1)

    {:ok, state}
  end

  @impl true
  @spec handle_info({:new_record, record}, state) :: {:noreply, state}
  def handle_info({:new_record, %Measurement{} = measurement}, state) do
    write_relay_state(measurement)

    {:noreply, state}
  end

  @impl true
  def handle_info({:new_record, _}, state), do: {:noreply, state}

  @spec start_link(state) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  defp write_relay_state(%Measurement{id: id} = measurement) do
    item = Enum.find(@sensors_map, &elem(&1, 0) === id)

    if is_nil(item) do
      Logger.warn(fn -> "There is no mapping for #{id} sensor" end)
    else
      {_, label, expected_value} = item

      label
      |> RelayState.new(measurement.value < expected_value)
      |> put_state()
    end
  end
end
