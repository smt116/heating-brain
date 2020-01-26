defmodule Collector.HeatingController do
  @moduledoc """
  The process that listens to relays states and controls heating relay depending on
  the state of valves.
  """

  use GenServer

  require Logger

  import Application, only: [get_env: 2]
  import Collector.Relays, only: [put_state: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  @typep id :: RelayState.id()
  @typep record :: Measurement.t() | RelayState.t()
  @typep value :: RelayState.value()

  @opaque state :: [timer: reference | nil, valves: list({id, value})]

  @heating_id :heating
  @initial_state [timer: nil, valves: []]

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    Storage.subscribe()

    {:ok, state}
  end

  @impl true
  @spec handle_info({:new_record, record}, state) :: {:noreply, state}
  def handle_info({:new_record, %RelayState{} = relay_state}, state) do
    if changes_heating_relay_state?(relay_state, state) do
      new_state =
        state
        |> put_in([:valves, relay_state.id], relay_state.value)
        |> schedule_heating_state_update()

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:new_record, _record}, state), do: {:noreply, state}

  @spec handle_info(:put_heating_state, state) :: {:noreply, state}
  def handle_info(:put_heating_state, state) do
    relay_state = any_valve_enabled?(state[:valves])

    Logger.debug(fn -> "Opened valves: #{inspect(state[:valves])}" end)
    RelayState.new(@heating_id, relay_state) |> put_state()

    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info(fn ->
      "Disabling heating relay due to termination (#{inspect(reason)})"
    end)

    RelayState.new(@heating_id, false) |> put_state()
  end

  @spec start_link(state) :: GenServer.on_start()
  def start_link(state) do
    state =
      Enum.reduce(@initial_state, state, fn {key, value}, acc ->
        Keyword.put_new(acc, key, value)
      end)

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(reference), do: Process.cancel_timer(reference)

  defp changes_heating_relay_state?(%RelayState{} = relay_state, state) do
    is_for_valve?(relay_state.id) && is_distinct?(relay_state, state)
  end

  defp is_distinct?(%RelayState{id: id, value: value}, state) do
    get_in(state, [:valves, id]) != value
  end

  defp is_for_valve?(l), do: to_string(l) |> String.starts_with?("valve")

  defp schedule_heating_state_update(state) do
    cancel_timer(state[:timer])
    delay = put_heating_state_delay(state[:valves])
    timer = Process.send_after(self(), :put_heating_state, delay)

    put_in(state, [:timer], timer)
  end

  def put_heating_state_delay(valves_states) do
    if any_valve_enabled?(valves_states) do
      get_env(:collector, :heating_controller_timer)
    else
      0
    end
  end

  def any_valve_enabled?(valves_states) do
    Enum.any?(valves_states, fn {_id, value} -> value end)
  end
end
