defmodule Collector.MeasurementTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest String.Chars.Collector.Measurement

  import Collector.Measurement, only: [new: 2, new: 4]

  alias Collector.Generators
  alias Collector.Measurement

  describe "new/2" do
    test "assigns timestamp and expected value (from config)" do
      assert %Measurement{id: :case, value: 22.5} = m = new(:case, 22.5)
      assert is_nil(m.expected_value)
      assert %DateTime{} = m.timestamp

      assert %Measurement{id: :bathroom} = m = new(:bathroom, 20.125)
      assert is_float(m.expected_value)
    end
  end

  describe "new/4" do
    property "converts attributes into the struct" do
      check all id <- atom(:alphanumeric),
                value <- float(),
                expected_value <- float(),
                timestamp <- Generators.timestamp() do
        assert %Measurement{} = m = new(id, value, expected_value, timestamp)

        assert m.id === id
        assert m.value === value
        assert m.expected_value === expected_value
        assert m.timestamp === timestamp
      end
    end
  end
end
