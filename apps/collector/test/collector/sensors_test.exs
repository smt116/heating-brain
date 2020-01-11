defmodule Collector.SensorsTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [current: 0, get: 0, get: 1]

  alias Collector.Measurement
  alias Collector.Storage

  setup do
    FilesystemMock.clear()
    :ok = Storage.subscribe()

    :ok
  end

  def write(%Measurement{} = measurement) do
    :ok = Storage.write(measurement)

    # Make sure that the storage had processed the message.
    assert_receive({:new_record, %Measurement{}})

    :ok
  end

  describe "current/0" do
    property "fetches latest values for each measurement from database" do
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
              |> Stream.map(&{&1.timestamp, &1.value})
              |> Enum.max_by(&elem(&1, 0))
            }
          end)

        assert current() === Enum.sort(expected_response)
      end
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
          |> Stream.map(fn {id, values} ->
            {
              id,
              values
              |> Stream.uniq_by(&{id, &1.timestamp})
              |> Stream.map(&{&1.timestamp, &1.value})
              |> Enum.sort_by(&elem(&1, 0))
            }
          end)
          |> Enum.sort_by(&elem(&1, 0))

        assert get() === expected_response
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

      assert [{^id1, _}] = get(&(&1.id == id1))
      assert get(&(&1.value == value)) |> Enum.any?(fn {id, _} -> id === id2 end)
    end
  end
end
