defmodule Collector.SensorsTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [get: 0, get: 1, read_all: 0]
  import Collector.Storage, only: [write: 1]

  setup do
    FilesystemGenerator.clear()

    :ok
  end

  describe "read_all/0" do
    test "reads measurements from the filesystem" do
      FilesystemGenerator.set_sensor(:foo, 23.187)
      FilesystemGenerator.set_sensor(:bar, 24.011)

      assert [
        %Collector.Measurement{
          id: :foo,
          timestamp: _,
          value: 23.187
        },
        %Collector.Measurement{
          id: :bar,
          timestamp: _,
          value: 24.011
        }
      ] = read_all()
    end

    test "does not include malformed readings" do
      FilesystemGenerator.set_sensor(:foo, 23.187)
      FilesystemGenerator.set_sensor(:bar, 24.011, malformed: true)

      assert [%Collector.Measurement{id: :foo, value: 23.187}] = read_all()
    end
  end

  describe "get/0" do
    property "fetches all measurements from the database" do
      check all measurements <- list_of(Generators.measurement()) do
        DatabaseHelper.clear_tables()
        Enum.each(measurements, &write/1)

        expected_response =
          measurements
          |> Enum.group_by(& &1.id)
          |> Enum.map(fn {id, values} ->
            {
              id,
              values
              |> Stream.uniq_by(& {id, &1.timestamp})
              |> Stream.map(&{&1.timestamp, &1.value})
              |> Enum.sort_by(&elem(&1, 0))
            }
          end)

        assert Enum.sort(get()) === Enum.sort(expected_response)
      end
    end
  end

  describe "get/1" do
    test "allows fetching a subset of measurements" do
      [
        %{id: id1},
        %{id: id2, value: value}
      ] = measurements = Enum.take(Generators.measurement(), 2)

      Enum.each(measurements, &write/1)

      assert [{^id1, _}] = get(& &1.id == id1)
      assert get(& &1.value == value) |> Enum.any?(fn {id, _} -> id === id2 end)
    end
  end
end
