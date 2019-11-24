defmodule Collector.StorageTest do
  use Collector.DataCase, async: false

  import Collector.Storage, only: [
    read: 2,
    subscribe: 0,
    unsubscribe: 1,
    write: 1
  ]

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

  describe "subscribe/0" do
    test "subscribes to storage events" do
      :ok = subscribe()

      measurement = ExUnitProperties.pick(Generators.measurement())
      assert :ok = write(measurement)

      assert_receive({:new_record, ^measurement})

      :ok = unsubscribe(self())
    end

    test "ensures process won't be subscribed twice" do
      :ok = subscribe()
      :ok = subscribe()
      :ok = subscribe()

      measurement = ExUnitProperties.pick(Generators.measurement())
      assert :ok = write(measurement)

      assert_receive({:new_record, ^measurement})
      refute_receive({:new_record, ^measurement})

      :ok = unsubscribe(self())
    end

    test "ensures process is usubscribed when it dies" do
      pid = Process.spawn(fn ->
        :ok = subscribe()
        Process.sleep(5_000)
      end, [])
      :erlang.trace(pid, true, [:receive])

      Process.exit(pid, :normal)

      measurement = ExUnitProperties.pick(Generators.measurement())
      assert :ok = write(measurement)

      refute_receive({:trace, ^pid, :receive, {:"$gen_cast", _}})
    end
  end

  describe "unsubscribe/0" do
    test "unsubscribes from storage events" do
      pid = Process.spawn(fn ->
        :ok = subscribe()
        Process.sleep(5_000)
      end, [])
      :erlang.trace(pid, true, [:receive])

      unsubscribe(pid)

      measurement = ExUnitProperties.pick(Generators.measurement())
      assert :ok = write(measurement)

      refute_receive({:trace, ^pid, :receive, {:"$gen_cast", _}})

      Process.exit(pid, :normal)
    end
  end
end
