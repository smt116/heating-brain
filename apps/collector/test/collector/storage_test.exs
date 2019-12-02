defmodule Collector.StorageTest do
  use Collector.DataCase, async: false

  import Collector.Storage, only: [
    read: 2,
    subscribe: 0,
    unsubscribe: 1,
    write: 1
  ]

  alias Collector.Measurement
  alias Collector.RelayState

  describe "write/1" do
    property "handles measurements" do
      check all measurement <- Generators.measurement() do
        DatabaseHelper.clear_tables()

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

    property "handles relays states" do
      check all relay_state <- Generators.relay_state() do
        DatabaseHelper.clear_tables()

        find = fn %{label: label} = item, acc ->
          if label === relay_state.label do
            [item | acc]
          else
            acc
          end
        end

        assert [] = read(find, RelayState)
        assert :ok = write(relay_state)
        assert [^relay_state] = read(find, RelayState)
      end
    end
  end

  describe "read/1" do
    test "reads filtered measurements" do
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

    test "reads filtered relays states" do
      relay_state =
        Generators.relay_state()
        |> ExUnitProperties.pick()
        |> Map.merge(%{value: true})
      relays_states = [relay_state | Enum.take(Generators.relay_state(), 9)]

      Enum.each(relays_states, &write/1)

      with_expected_value = fn %{value: value} = item, acc ->
        if value do
          [item | acc]
        else
          acc
        end
      end

      actual =
        with_expected_value
        |> read(RelayState)
        |> Enum.sort_by(&{&1.label, &1.timestamp})

      expected =
        relays_states
        |> Stream.filter(& &1.value)
        |> Enum.sort_by(&{&1.label, &1.timestamp})

      refute Enum.member?(relays_states, expected)
      assert actual === expected
    end
  end

  describe "subscribe/0" do
    test "subscribes to storage events" do
      :ok = subscribe()

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

      assert_receive({:new_record, ^record})

      :ok = unsubscribe(self())
    end

    test "ensures process won't be subscribed twice" do
      :ok = subscribe()
      :ok = subscribe()
      :ok = subscribe()

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

      assert_receive({:new_record, ^record})
      refute_receive({:new_record, ^record})

      :ok = unsubscribe(self())
    end

    test "ensures process is usubscribed when it dies" do
      pid = Process.spawn(fn ->
        :ok = subscribe()
        Process.sleep(5_000)
      end, [])
      :erlang.trace(pid, true, [:receive])

      Process.exit(pid, :normal)

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

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

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

      refute_receive({:trace, ^pid, :receive, {:"$gen_cast", _}})

      Process.exit(pid, :normal)
    end
  end
end
