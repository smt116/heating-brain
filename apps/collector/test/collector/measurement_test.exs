defmodule Collector.MeasurementTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest String.Chars.Collector.Measurement

  import Collector.Measurement, only: [initialize: 2]

  alias Collector.Measurement

  describe "initialize/2" do
    property "converts attributes into the struct with timestamp" do
      check all raw_id <- string(:printable),
                value <- float() do
        assert %Measurement{} = measurement = initialize(raw_id, value)

        assert is_atom(measurement.id)
        assert measurement.id === String.to_atom(raw_id)

        assert measurement.value === value
        assert %DateTime{} = measurement.timestamp
      end
    end
  end
end
