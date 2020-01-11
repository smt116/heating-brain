defmodule Collector.OneWireWorkerTest do
  use Collector.DataCase, async: false

  import Collector.OneWireWorker

  alias Collector.Measurement

  setup do
    FilesystemMock.clear()
  end

  describe "read_all/0" do
    test "returns a list of measurements from the filesystem" do
      FilesystemMock.set_sensor(:foo, -32.125)
      FilesystemMock.set_sensor(:bar, 24.011)

      assert [
               {:ok,
                %Measurement{
                  id: :bar,
                  timestamp: _,
                  value: 24.011
                }},
               {:ok,
                %Measurement{
                  id: :foo,
                  timestamp: _,
                  value: -32.125
                }}
             ] = read_all()
    end
  end

  test "includes error tuples for failed readings" do
    FilesystemMock.set_sensor(:foo, 24.011, malformed: true)
    FilesystemMock.set_sensor(:bar, 85.0)
    FilesystemMock.set_sensor(:baz, 24.011)

    assert [
             ok: %Collector.Measurement{
               id: :baz,
               timestamp: _,
               value: 24.011
             },
             error: "bar reported power-on reset value",
             error: "foo read failed: \"60 01 4b 14 : crc=14 NO\\n7f ff 0c 10 14 t=24011\\n\""
           ] = read_all()
  end
end
