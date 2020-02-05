defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  import Collector, only: [sensor_id_to_relay_id: 1]

  alias Collector.Measurement
  alias Collector.RelayState

  @type measurement :: Measurement.t()
  @type relay_state :: RelayState.t()
  @type datetime :: DateTime.t()

  @type chart_data :: {Measurement.id(), {measurement, relay_state, data}}
  @type data :: [
          expected_values: list(point),
          states: list(point),
          values: list(point)
        ]
  @type point :: %{x: DateTime.t(), y: Measurement.value() | RelayState.value()}

  @within 3200

  defdelegate relay_id_to_sensor_id(id), to: Collector
  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe

  @spec sensors_chart_data :: list(chart_data)
  def sensors_chart_data do
    relays_states_data = Collector.relays_states(@within)

    @within
    |> Collector.sensors_readings()
    |> Enum.map(fn {id, measurements} ->
      states = Keyword.get(relays_states_data, sensor_id_to_relay_id(id), [])
      current_measurement = Enum.fetch!(measurements, -1)
      current_state = Enum.at(states, -1)

      datasets =
        measurements
        |> sensor_chart_data()
        |> Keyword.merge(states: states_data(states))
        |> Stream.map(fn {k, v} -> {k, Enum.sort_by(v, & &1.x)} end)
        |> Enum.into(%{})

      {id, {current_measurement, current_state, datasets}}
    end)
  end

  defp sensor_chart_data(measurements) do
    Enum.reduce(measurements, [expected_values: [], values: []], fn m, acc ->
      acc
      |> get_and_update_in(
        [:expected_values],
        &{&1, [%{x: m.timestamp, y: m.expected_value} | &1]}
      )
      |> elem(1)
      |> get_and_update_in([:values], &{&1, [%{x: m.timestamp, y: m.value} | &1]})
      |> elem(1)
    end)
  end

  defp states_data(states) do
    Enum.map(
      states,
      &%{
        x: &1.timestamp,
        y: if(&1.value === true, do: 1, else: 0)
      }
    )
  end
end
