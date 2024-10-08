defmodule Collector.RelaysTest do
  use Collector.DataCase, async: false

  import Collector.RelayState, only: [new: 2]

  import Collector.Relays,
    only: [
      put_state: 1,
      read_all: 0,
      select: 1,
      select: 2
    ]

  import Collector.Storage, only: [write: 1]

  alias Collector.Relays
  alias Collector.RelayState
  alias Collector.Storage

  @relays_map Application.get_env(:heating_brain, :relays_map)

  describe "put_state/1" do
    test "writes the new state to the filesystem" do
      assert read_all() |> Enum.find(&(&1.id === :valve1 && &1.value === false))

      new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.id === :valve1 && &1.value === true))
    end

    test "writes the new state to the storage" do
      Storage.subscribe()

      new(:valve1, true) |> put_state()

      assert_receive({:new_record, %RelayState{id: :valve1, value: true}})

      self() |> Storage.unsubscribe()
    end

    test "does not change the state if it is already set" do
      new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.id === :valve1 && &1.value === true))

      new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.id === :valve1 && &1.value === true))
    end
  end

  describe "read_all/0" do
    test "reads states from the filesystem" do
      FilesystemMock.set_relay(:heating, true)
      FilesystemMock.set_relay(:valve1, true)

      assert [
               %RelayState{
                 id: :heating,
                 value: true
               },
               %RelayState{
                 id: :pump,
                 value: false
               },
               %RelayState{
                 id: :valve1,
                 value: true
               },
               %RelayState{
                 id: :valve2,
                 value: false
               }
             ] = read_all()
    end
  end

  describe "select/1" do
    test "fetches states within time boundary for all relays" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)
      obsolete = DateTime.add(now, -301, :second)

      new(:valve1, false) |> Map.put(:timestamp, now) |> write()
      new(:heating, true) |> Map.put(:timestamp, before) |> write()
      new(:heating, false) |> Map.put(:timestamp, obsolete) |> write()

      assert [
               heating: [
                 %RelayState{id: :heating, value: true, timestamp: ^before}
               ],
               valve1: [
                 %RelayState{id: :valve1, value: false, timestamp: ^now}
               ]
             ] = select(300)

      assert [
               heating: [
                 %RelayState{id: :heating, value: false, timestamp: ^obsolete},
                 %RelayState{id: :heating, value: true, timestamp: ^before}
               ],
               valve1: [
                 %RelayState{id: :valve1, value: false, timestamp: ^now}
               ]
             ] = select(310)
    end
  end

  describe "select/2" do
    test "fetches states within time boundary for a given relay" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)

      new(:valve2, false) |> Map.put(:timestamp, now) |> write()
      new(:valve2, true) |> Map.put(:timestamp, before) |> write()

      assert [
               %RelayState{id: :valve2, value: false, timestamp: ^now}
             ] = select(:valve2, 5)

      assert [
               %RelayState{id: :valve2, value: true, timestamp: ^before},
               %RelayState{id: :valve2, value: false, timestamp: ^now}
             ] = select(:valve2, 6)
    end
  end

  describe "setup_all/0" do
    test "exports all relays" do
      FilesystemMock.clear()

      has_all_relays_exported = fn ->
        paths = FilesystemMock.paths()

        Enum.all?(@relays_map, fn {_, pin, _, _} ->
          paths
          |> Enum.find(&(&1 === "/sys/class/gpio/gpio#{pin}/value"))
          |> is_binary()
        end)
      end

      refute has_all_relays_exported.()

      Relays.setup_all()

      assert has_all_relays_exported.()
    end
  end
end
