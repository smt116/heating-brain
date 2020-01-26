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

  def measurement do
    gen all id <- id(),
            timestamp <- timestamp(),
            value <- temp() do
      %Measurement{
        id: id,
        timestamp: timestamp,
        value: value
      }
    end
  end

  def record, do: one_of([measurement(), relay_state()])

  def relay_state do
    gen all label <- one_of([:heating, :pump, :valve1, :valve2]),
            timestamp <- timestamp(),
            value <- boolean() do
      %RelayState{
        label: label,
        timestamp: timestamp,
        value: value
      }
    end
  end

  def temp, do: map(float(min: -30.0, max: 60.0), &Float.round(&1, 3))

  defp timestamp do
    map(
      positive_integer(),
      &(utc_now() |> DateTime.add(-&1, :second) |> DateTime.truncate(:second))
    )
  end
end
