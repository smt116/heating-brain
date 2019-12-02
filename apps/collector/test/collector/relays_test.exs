defmodule Collector.RelaysTest do
  use Collector.DataCase, async: false

  import Collector.Relays, only: [current: 0]
  import Collector.Storage, only: [write: 1]

  setup do
    FilesystemMock.clear()

    :ok
  end

  describe "current/0" do
    property "fetches latest states for each relay from the database" do
      check all relay_states <- list_of(Generators.relay_state()) do
        DatabaseHelper.clear_tables()
        Enum.each(relay_states, &write/1)

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
    end
  end

  describe "put_state/1" do
    test "writes the new state to the filesystem"
    test "does not change the state if it is already set"
  end

  describe "read_all/0" do
    test "reads states from the filesystem"
  end

  describe "setup_all/0" do
    test "exports all relays"
  end
end
