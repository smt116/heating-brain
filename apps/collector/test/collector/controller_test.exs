defmodule Collector.ControllerTest do
  use Collector.DataCase, async: false

  import Application, only: [get_env: 2]
  import Collector.Relays, only: [put_state: 1, read_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement
  alias Collector.RelayState
  alias Collector.Storage

  setup do
    Storage.subscribe()

    :ok
  end

  test "enables valve when the sensor reports temperature lower than expected" do
    RelayState.new(:valve1, true) |> put_state()

    at =
      DateTime.utc_now()
      |> DateTime.shift_zone!(get_env(:collector, :timezone))
      |> Map.put(:hour, 6)

    RelayState.new(:valve1, false) |> put_state()
    Measurement.new(:living_room, 18.5, at) |> write()
    assert_receive({:new_record, %RelayState{id: :valve1, value: true}})

    # FIXME
    :timer.sleep(50)

    refute read_all() |> Enum.find(&(&1.id === :valve1 && &1.value)) |> is_nil()
  end

  test "disables valve when the sensor reports temperature higher than expected" do
    RelayState.new(:valve2, true) |> put_state()

    at =
      DateTime.utc_now()
      |> DateTime.shift_zone!(get_env(:collector, :timezone))
      |> Map.put(:hour, 6)

    RelayState.new(:valve2, false) |> put_state()
    Measurement.new(:bathroom, 20.6, at) |> write()
    assert_receive({:new_record, %RelayState{id: :valve2, value: true}})

    # FIXME
    :timer.sleep(50)

    assert read_all() |> Enum.find(&(&1.id === :valve2 && &1.value)) |> is_nil()
  end

  test "ignores sensor without relevant valve" do
    Measurement.new(:unknown, 0.0) |> write()
    refute_received({:new_record, %RelayState{}})
  end
end
