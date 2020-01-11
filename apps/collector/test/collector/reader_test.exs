defmodule Collector.ReaderTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [get: 0]
  import ExUnit.CaptureLog

  alias Collector.Reader
  alias Collector.Storage

  setup do
    FilesystemMock.clear()
    Storage.subscribe()
  end

  describe "handle_info/2 for read_all" do
    test "writes readings into the database" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011)

      Process.whereis(Reader) |> Process.send(:read_all, [])

      Enum.each(1..2, fn _ -> assert_receive({:new_record, _}) end)

      assert [
               bar: [{_, 24.011}],
               foo: [{_, 23.187}]
             ] = get()
    end

    test "logs malformed readings" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011, malformed: true)

      assert capture_log(fn ->
               Process.whereis(Reader) |> Process.send(:read_all, [])
               assert_receive({:new_record, _})

               assert [foo: [{_, 23.187}]] = get()
             end) =~ "bar read failed"
    end

    test "logs failed readings due to the power-on reset value" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 85.0)

      assert capture_log(fn ->
               Process.whereis(Reader) |> Process.send(:read_all, [])
               assert_receive({:new_record, _})

               assert [foo: [{_, 23.187}]] = get()
             end) =~ "bar reported power-on reset value"
    end
  end
end
