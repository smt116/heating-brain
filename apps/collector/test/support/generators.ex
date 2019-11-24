defmodule Collector.Generators do
  @moduledoc """
  Generators for property-based testing.
  """

  import DateTime, only: [utc_now: 0]
  import ExUnitProperties
  import StreamData

  alias Collector.Measurement

  def id, do: atom(:alphanumeric)

  def measurement do
    gen all id <- id(),
            timestamp <- timestamp(),
            value <- value() do
      %Measurement{
        id: id,
        timestamp: timestamp,
        value: value
      }
    end
  end

  def timestamp do
    map(
      positive_integer(),
      &utc_now() |> DateTime.add(- &1, :second) |> DateTime.truncate(:second)
    )
  end

  def value, do: map(float(min: 16.0, max: 32.0), &Float.round(&1, 3))
end
