defmodule Collector.RelaysTest do
  use Collector.DataCase, async: false

  import Collector.Relays, only: [current: 0, put_state: 1, read_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Relays
  alias Collector.RelayState
  alias Collector.Storage

  @relays_map Application.get_env(:collector, :relays_map)

  setup do
    FilesystemMock.reset()

    :ok
  end

  describe "current/0" do
    property "fetches latest states for each relay from the database" do
      :ok = Storage.subscribe()

      check all relay_states <- list_of(Generators.relay_state()) do
        DatabaseHelper.clear_tables()
        Enum.each(relay_states, fn state ->
          :ok = write(state)

          # Make sure that the storage had processed the message.
          assert_receive({:new_record, %RelayState{}})
        end)

        expected_response =
          relay_states
          |> Enum.group_by(& &1.label)
          |> Enum.map(fn {label, values} ->
            {
              label,
              values
              |> Stream.map(&{&1.timestamp, &1.value})
              |> Enum.max_by(&elem(&1, 0))
            }
          end)

        assert Enum.sort(current()) === Enum.sort(expected_response)
      end

      :ok = self() |> Storage.unsubscribe()
    end
  end

  describe "put_state/1" do
    test "writes the new state to the filesystem" do
      assert read_all() |> Enum.find(&(&1.label === :valve1 && &1.value === false))

      RelayState.new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.label === :valve1 && &1.value === true))
    end

    test "writes the new state to the storage" do
      Storage.subscribe()

      RelayState.new(:valve1, true) |> put_state()

      assert_receive({:new_record, %RelayState{label: :valve1, value: true}})

      self() |> Storage.unsubscribe()
    end

    test "does not change the state if it is already set" do
      RelayState.new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.label === :valve1 && &1.value === true))

      RelayState.new(:valve1, true) |> put_state()

      assert read_all() |> Enum.find(&(&1.label === :valve1 && &1.value === true))
    end
  end

  describe "read_all/0" do
    test "reads states from the filesystem" do
      FilesystemMock.set_relay(:heating, true)
      FilesystemMock.set_relay(:valve1, true)

      assert [
               %RelayState{
                 label: :circulation,
                 value: false
               },
               %RelayState{
                 label: :heating,
                 value: true
               },
               %RelayState{
                 label: :pump,
                 value: false
               },
               %RelayState{
                 label: :valve1,
                 value: true
               },
               %RelayState{
                 label: :valve2,
                 value: false
               },
               %RelayState{
                 label: :valve3,
                 value: false
               },
               %RelayState{
                 label: :valve4,
                 value: false
               },
               %RelayState{
                 label: :valve5,
                 value: false
               },
               %RelayState{
                 label: :valve6,
                 value: false
               }
             ] = read_all()
    end
  end

  describe "setup_all/0" do
    test "exports all relays" do
      FilesystemMock.clear()

      has_all_relays_exported = fn ->
        paths = FilesystemMock.paths()

        Enum.all?(@relays_map, fn {_, pin, _} ->
          Enum.find(paths, &(&1 === "/sys/class/gpio/#{pin}/value")) |> is_binary()
        end)
      end

      refute has_all_relays_exported.()

      Relays.setup_all()

      assert has_all_relays_exported.()
    end
  end
end
