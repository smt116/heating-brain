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
  @typep load :: float | nil
  @typep record :: Measurement.t() | RelayState.t()
  @typep value :: RelayState.value()

  @opaque state :: [
            load_map: list({id, load}),
            timer: reference | nil,
            valves: list({id, value})
          ]

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
    if has_impact_on_heating_relay_state?(relay_state, state) do
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
    relay_state = any_valve_enabled?(state) && minimum_load_ensured?(state)

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
    load_map =
      get_env(:heating_brain, :relays_map)
      |> Stream.filter(&(elem(&1, 0) |> is_for_valve?()))
      |> Enum.map(fn {id, _, _, load} -> {id, load || 0.0} end)

    state =
      @initial_state
      |> Enum.reduce(state, fn {k, v}, acc -> Keyword.put_new(acc, k, v) end)
      |> Keyword.put_new(:load_map, load_map)

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(reference), do: Process.cancel_timer(reference)

  defp has_impact_on_heating_relay_state?(%RelayState{} = relay_state, state) do
    is_for_valve?(relay_state.id) && is_distinct?(relay_state, state)
  end

  defp is_distinct?(%RelayState{id: id, value: value}, state) do
    get_in(state, [:valves, id]) != value
  end

  defp is_for_valve?(l), do: to_string(l) |> String.starts_with?("valve")

  defp schedule_heating_state_update(state) do
    cancel_timer(state[:timer])
    delay = put_heating_state_delay(state)
    timer = Process.send_after(self(), :put_heating_state, delay)

    put_in(state, [:timer], timer)
  end

  def put_heating_state_delay(state) do
    if any_valve_enabled?(state) && minimum_load_ensured?(state) do
      get_env(:heating_brain, :heating_controller_timer)
    else
      0
    end
  end

  def any_valve_enabled?(state) do
    Enum.any?(state[:valves], fn {_id, value} -> value end)
  end

  def minimum_load_ensured?(state) do
    load =
      state[:valves]
      |> Stream.filter(fn {_id, value} -> value end)
      |> Stream.map(fn {id, _value} -> get_in(state, [:load_map, id]) end)
      |> Enum.sum()

    load >= get_env(:heating_brain, :heating_controller_required_load)
  end
end
