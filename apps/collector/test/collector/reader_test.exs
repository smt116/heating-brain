defmodule Collector.ReaderTest do
  use Collector.DataCase, async: false

  import Collector.Sensors, only: [select: 2]
  import ExUnit.CaptureLog

  alias Collector.Measurement
  alias Collector.Reader
  alias Collector.Storage

  setup do
    Storage.subscribe()
  end

  describe "handle_info/2 for read_all" do
    test "writes readings into the database" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011)

      Process.whereis(Reader) |> Process.send(:read_all, [])

      Enum.each(1..2, fn _ -> assert_receive({:new_record, _}) end)

      assert [%Measurement{value: 23.187}] = select(:foo, 5)
      assert [%Measurement{value: 24.011}] = select(:bar, 5)
    end

    test "logs malformed readings" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 24.011, malformed: true)

      assert capture_log(fn ->
               Process.whereis(Reader) |> Process.send(:read_all, [])
               assert_receive({:new_record, _})

               assert [%Measurement{value: 23.187}] = select(:foo, 5)
               assert [] = select(:bar, 5)
             end) =~ "bar read failed"
    end

    test "logs failed readings due to the power-on reset value" do
      FilesystemMock.set_sensor(:foo, 23.187)
      FilesystemMock.set_sensor(:bar, 85.0)

      assert capture_log(fn ->
               Process.whereis(Reader) |> Process.send(:read_all, [])
               assert_receive({:new_record, _})

               assert [%Measurement{value: 23.187}] = select(:foo, 5),
                      assert([] = select(:bar, 5))
             end) =~ "bar reported power-on reset value"
    end
  end
end
