defmodule Collector.ControllerTest do
  use Collector.DataCase, async: false

  import Collector.Relays, only: [put_state: 1, read_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  setup do
    FilesystemMock.reset()
    Storage.subscribe()

    :ok
  end

  test "enables valve when the sensor reports temperature lower than expected" do
    RelayState.new(:valve1, false) |> put_state()
    Measurement.new("28-01187615e4ff", 24.0) |> write()
    assert_receive({:new_record, %RelayState{label: :valve1, value: true}})

    refute read_all() |> Enum.find(& &1.label === :valve1 && &1.value) |> is_nil()
  end

  test "disables valve when the sensor reports temperature higher than expected" do
    RelayState.new(:valve1, true) |> put_state()
    Measurement.new("28-01187615e4ff", 26.0) |> write()
    assert_receive({:new_record, %RelayState{label: :valve1, value: false}})

    assert read_all() |> Enum.find(& &1.label === :valve1 && &1.value) |> is_nil()
  end

  test "ignores sensor without relevant valve" do
    Measurement.new("unknown", 0.0) |> write()
    refute_receive({:new_record, %RelayState{label: :unknown}})
  end
end
