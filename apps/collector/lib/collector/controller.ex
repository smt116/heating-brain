defmodule Collector.Controller do
  @moduledoc """
  The process that listens to the storage's events and controls relays.
  """

  use GenServer

  require Logger

  import Application, only: [get_env: 2]
  import Collector.Relays, only: [put_state: 1, read_all: 0, setup_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  @typep id :: RelayState.id()
  @typep record :: Measurement.t() | RelayState.t()
  @typep value :: RelayState.value()

  @opaque state :: [{id, {value, reference | nil}}]

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    Storage.subscribe()

    setup_all()
    read_all() |> Enum.each(&write/1)

    {:ok, state}
  end

  @impl true
  @spec handle_info({:new_record, record}, state) :: {:noreply, state}
  def handle_info({:new_record, %Measurement{id: id} = measurement}, state) do
    item = get_env(:collector, :sensors_map) |> Enum.find(&(elem(&1, 0) === id))

    new_state =
      if is_nil(item) do
        Logger.debug(fn -> "There is no mapping for #{id} sensor" end)

        state
      else
        {_, id, expected_value} = item

        state
        |> Keyword.put_new(id, {nil, nil})
        |> Keyword.get_and_update(id, fn {_value, timer} = current ->
          {current, {measurement.value < expected_value, timer}}
        end)
        |> schedule_relay_state_update(id)
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:new_record, _}, state), do: {:noreply, state}

  @spec handle_info({:put_relay_state, id}, state) :: {:noreply, state}
  def handle_info({:put_relay_state, id}, state) do
    {value, _} = state[id]
    new_state = Keyword.update!(state, id, fn {value, _} -> {value, nil} end)

    RelayState.new(id, value) |> put_state()

    {:noreply, new_state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info(fn ->
      "Disabling all relays due to termination (#{inspect(reason)})"
    end)

    get_env(:collector, :relays_map)
    |> Stream.map(fn {id, _pin, _direction} -> id end)
    |> Stream.filter(&(&1 |> to_string() |> String.starts_with?("valve")))
    |> Enum.each(&(RelayState.new(&1, false) |> put_state()))
  end

  @spec start_link(state) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # FIXME: duplicated in `HeatingController`
  defp cancel_timer(nil), do: :ok
  defp cancel_timer(reference), do: Process.cancel_timer(reference)

  defp schedule_relay_state_update({{previous_value, timer}, state}, id) do
    {new_value, _timer} = state[id]

    if previous_value === new_value do
      state
    else
      Logger.debug(fn ->
        "Relay state for #{id} is going to change from #{previous_value}" <>
          " to #{new_value}"
      end)

      cancel_timer(timer)
      delay = get_env(:collector, :relay_controller_timer)
      new_timer = Process.send_after(self(), {:put_relay_state, id}, delay)

      Keyword.update!(state, id, fn {value, _} -> {value, new_timer} end)
    end
  end
end
