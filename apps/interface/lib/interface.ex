defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  import DateTime, only: [to_time: 1]

  alias Collector.Measurement

  @type measurement :: Measurement.t()
  @type time :: Time.t()
  @type value :: Measurement.value()

  @type chart_data :: {Measurement.id(), measurement, data}
  @type data :: [labels: list(time), values: value, expected_values: value]

  # 12 hours
  @within 43_200

  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe
  defdelegate relays_states(within), to: Collector

  @spec sensors_chart_data :: list(chart_data)
  def sensors_chart_data do
    @within
    |> Collector.sensors_readings()
    |> Enum.map(fn {id, measurements} ->
      newest = Enum.fetch!(measurements, -1)

      data =
        Enum.reduce(measurements, [labels: [], values: [], expected_values: []], fn m, acc ->
          acc
          |> get_and_update_in([:labels], &{&1, [to_time(m.timestamp) | &1]})
          |> elem(1)
          |> get_and_update_in([:values], &{&1, [m.value | &1]})
          |> elem(1)
          |> get_and_update_in([:expected_values], &{&1, [m.expected_value | &1]})
          |> elem(1)
        end)

      {id, {newest, Enum.map(data, fn {k, v} -> {k, Enum.sort(v)} end)}}
    end)
  end
end
