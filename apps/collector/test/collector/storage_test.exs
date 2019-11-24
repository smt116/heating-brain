defmodule Collector.StorageTest do
  use Collector.DataCase, async: false

  import Collector.Storage, only: [read: 2, write: 1]

  alias Collector.Measurement

  describe "write/1" do
    property "writes a given struct into database" do
      check all measurement <- Generators.measurement() do
        DatabaseHelper.clear_measurements_table()

        find = fn %{id: id} = item, acc ->
          if id === measurement.id do
            [item | acc]
          else
            acc
          end
        end

        assert [] = read(find, Measurement)
        assert :ok = write(measurement)
        assert [^measurement] = read(find, Measurement)
      end
    end
  end

  describe "read/1" do
    test "reads filtered data from a given table" do
      measurement =
        Generators.measurement()
        |> ExUnitProperties.pick()
        |> Map.merge(%{value: 10.0})
      measurements = [measurement | Enum.take(Generators.measurement(), 9)]

      Enum.each(measurements, &write/1)

      with_expected_value = fn %{value: value} = item, acc ->
        if value > 15.0 do
          [item | acc]
        else
          acc
        end
      end

      actual =
        with_expected_value
        |> read(Measurement)
        |> Enum.sort_by(&{&1.id, &1.timestamp})

      expected =
        measurements
        |> Stream.filter(& &1.value > 15.0)
        |> Enum.sort_by(&{&1.id, &1.timestamp})

      refute Enum.member?(measurements, expected)
      assert actual === expected
    end
  end
end
