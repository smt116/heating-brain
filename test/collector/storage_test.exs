defmodule Collector.StorageTest do
  use Collector.DataCase, async: false

  import Collector.Storage, only: [subscribe: 0, unsubscribe: 1, write: 1]

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
      refute_received({:new_record, ^record})

      :ok = unsubscribe(self())
    end

    test "ensures process is usubscribed when it dies" do
      pid =
        Process.spawn(
          fn ->
            :ok = subscribe()
            Process.sleep(5_000)
          end,
          []
        )

      :erlang.trace(pid, true, [:receive])

      Process.exit(pid, :normal)

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

      refute_received({:trace, ^pid, :receive, {:"$gen_cast", _}})
    end
  end

  describe "unsubscribe/0" do
    test "unsubscribes from storage events" do
      pid =
        Process.spawn(
          fn ->
            :ok = subscribe()
            Process.sleep(5_000)
          end,
          []
        )

      :erlang.trace(pid, true, [:receive])

      unsubscribe(pid)

      record = ExUnitProperties.pick(Generators.record())
      assert :ok = write(record)

      refute_received({:trace, ^pid, :receive, {:"$gen_cast", _}})

      Process.exit(pid, :normal)
    end
  end
end
