defmodule Collector.HeatingController do
  @moduledoc """
  The process that listens to relays states and controls heating relay depending on
  the state of valves.
  """

  use GenServer

  require Logger

  import Collector.Relays, only: [put_state: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  @typep label :: RelayState.label()
  @typep record :: Measurement.t() | RelayState.t()
  @typep value :: RelayState.value()

  @opaque state :: [timer: reference | nil, valves: list({label, value})]

  @heating_label :heating
  @initial_state [timer: nil, valves: []]
  @timer 5_000

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
      {:noreply, schedule_heating_state_update(relay_state, state)}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:new_record, _record}, state), do: {:noreply, state}

  @spec handle_info(:put_heating_state, state) :: {:noreply, state}
  def handle_info(:put_heating_state, state) do
    relay_state = Enum.any?(state[:valves])

    Logger.debug(fn -> "Opened valves: #{inspect(state[:valves])}" end)
    RelayState.new(@heating_label, relay_state) |> put_state()

    {:noreply, state}
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
    is_for_valve?(relay_state.label) && is_distinct?(relay_state, state)
  end

  defp is_distinct?(%RelayState{label: label, value: value}, state) do
    get_in(state, [:valves, label]) != value
  end

  defp is_for_valve?(l), do: to_string(l) |> String.starts_with?("valve")

  defp schedule_heating_state_update(%RelayState{} = relay_state, state) do
    cancel_timer(state[:timer])
    timer = Process.send_after(self(), :put_heating_state, @timer)

    state
    |> put_in([:valves, relay_state.label], relay_state.value)
    |> put_in([:timer], timer)
  end
end
