defmodule Collector.SensorsTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [current: 0, get: 0, get: 1, read_all: 0]
  import ExUnit.CaptureLog

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

        assert Enum.sort(current()) === Enum.sort(expected_response)
      end
    end
  end

  describe "read_all/0" do
    test "reads measurements from the filesystem" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011)
      FilesystemMock.set_sensor(:baz, -0.125)

      assert [
               %Collector.Measurement{
                 id: :baz,
                 timestamp: _,
                 value: -0.125
               },
               %Collector.Measurement{
                 id: :bar,
                 timestamp: _,
                 value: 24.011
               },
               %Collector.Measurement{
                 id: :foo,
                 timestamp: _,
                 value: 23.187
               }
             ] = read_all()
    end

    test "does not include malformed readings" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011, malformed: true)

      assert capture_log(fn ->
               assert [%Collector.Measurement{id: :foo, value: 23.187}] = read_all()
             end) =~ "The bar sensor read failed"
    end

    test "does not include readings with power-on reset value" do
      FilesystemMock.set_sensor(:foo, 85.0)
      FilesystemMock.set_sensor(:bar, 24.011)

      assert capture_log(fn ->
               assert [%Collector.Measurement{id: :bar, value: 24.011}] = read_all()
             end) =~ "The foo sensor reported power-on reset value"
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
              |> Stream.uniq_by(&{id, &1.timestamp})
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

      assert [{^id1, _}] = get(&(&1.id == id1))
      assert get(&(&1.value == value)) |> Enum.any?(fn {id, _} -> id === id2 end)
    end
  end
end
