defmodule Collector.Generators do
  @moduledoc """
  Generators for property-based testing.
  """

  import DateTime, only: [utc_now: 0]
  import ExUnitProperties
  import StreamData

  alias Collector.Measurement
  alias Collector.RelayState

  def id, do: atom(:alphanumeric)

  def measurement_id do
    Application.get_env(:collector, :sensors_map)
    |> Enum.map(&elem(&1, 1))
    |> one_of()
  end

  def measurement do
    gen all id <- measurement_id(),
            timestamp <- timestamp(),
            value <- temp(),
            expected_value <- temp() do
      Measurement.new(id, value, expected_value, timestamp)
    end
  end

  def record, do: one_of([measurement(), relay_state()])

  def relay_state do
    gen all id <- one_of([:heating, :pump, :valve1, :valve2]),
            timestamp <- timestamp(),
            value <- boolean() do
      RelayState.new(id, value, timestamp)
    end
  end

  def temp, do: map(float(min: -30.0, max: 60.0), &Float.round(&1, 3))

  def timestamp do
    map(
      positive_integer(),
      &(utc_now() |> DateTime.add(-&1, :second) |> DateTime.truncate(:second))
    )
  end
end
