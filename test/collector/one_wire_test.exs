defmodule Collector.OneWireTest do
  use Collector.DataCase, async: false

  import Collector.OneWire

  alias Collector.Measurement

  describe "sensors/0" do
    test "converts id into the label when set in config" do
      FilesystemMock.set_sensor(:"28-01187615e4ff", 11.3)
      FilesystemMock.set_sensor(:unknown, 14.5)

      assert sensors() === [:living_room, :unknown]
    end

    property "returns a list of available sensors" do
      check all tuples <- list_of(tuple({Generators.id(), Generators.temp()})) do
        tuples
        |> Stream.uniq_by(fn {id, _} -> id end)
        |> Enum.each(fn {id, temp} -> FilesystemMock.set_sensor(id, temp) end)

        expected_ids =
          tuples
          |> Stream.map(fn {id, _} -> id end)
          |> Stream.uniq()
          |> Enum.sort()

        assert sensors() === expected_ids

        FilesystemMock.reset()
      end
    end
  end

  describe "read/1" do
    property "reads the measurement from the filesystem" do
      check all measurement <- Generators.measurement() do
        %{
          id: id,
          value: value
        } = measurement

        FilesystemMock.set_sensor(measurement.id, measurement.value)

        assert {:ok,
                %Measurement{
                  id: ^id,
                  timestamp: _,
                  value: actual_value
                }} = read(measurement.id)

        assert Float.round(actual_value, 1) === Float.round(value, 1)

        FilesystemMock.reset()
      end
    end

    test "returns an error tuple on malformed reading" do
      FilesystemMock.set_sensor(:foo, 24.011, malformed: true)

      assert read(:foo) ===
               {:error,
                "foo sensor read failed: \"60 01 4b 14 : crc=14 NO\\n" <>
                  "7f ff 0c 10 14 t=24011\\n\""}
    end

    test "does not include readings with power-on reset value" do
      FilesystemMock.set_sensor(:foo, 85.0)

      assert read(:foo) === {:error, "foo sensor reported power-on reset value"}
    end
  end
end
