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
    value = map(float(min: 16.0, max: 32.0), &Float.round(&1, 3))

    gen all id <- id(),
            timestamp <- timestamp(),
            value <- value do
      %Measurement{
        id: id,
        timestamp: timestamp,
        value: value
      }
    end
  end

  def record, do: one_of([measurement(), relay_state()])

  def relay_state do
    gen all label <- id(),
            timestamp <- timestamp(),
            value <- boolean() do
      %RelayState{
        label: label,
        timestamp: timestamp,
        value: value
      }
    end
  end

  defp timestamp do
    map(
      positive_integer(),
      &utc_now() |> DateTime.add(- &1, :second) |> DateTime.truncate(:second)
    )
  end
end
