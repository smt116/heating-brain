defmodule Collector.ReaderTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [get: 0]

  alias Collector.Reader
  alias Collector.Storage

  setup do
    FilesystemGenerator.clear_sensors()

    :ok
  end

  describe "handle_info/2" do
    test "read_all writes readings into the database" do
      FilesystemGenerator.set_sensor(:foo, 23.187)
      FilesystemGenerator.set_sensor(:bar, 24.011)

      :ok = Storage.subscribe()

      Process.whereis(Reader) |> Process.send(:read_all, [])

      Enum.each(1..2, fn _ -> assert_receive({:new_record, _}, 1_000) end)

      assert [
        bar: [{_, 24.011}],
        foo: [{_, 23.187}]
      ] = get() |> Enum.sort()

      :ok = Storage.unsubscribe(self())
    end
  end
end
