defmodule Collector.RelayStateTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest String.Chars.Collector.RelayState

  import Collector.RelayState, only: [new: 2, new: 3]

  alias Collector.Generators
  alias Collector.RelayState

  describe "new/2" do
    test "assigns timestamp" do
      assert %RelayState{id: :valve1, value: true} = relay = new(:valve1, true)
      assert %DateTime{} = relay.timestamp
    end
  end

  describe "new/3" do
    property "converts attributes into the struct" do
      check all id <- atom(:alphanumeric),
                value <- boolean(),
                timestamp <- Generators.timestamp() do
        assert %RelayState{} = relay = new(id, value, timestamp)

        assert relay.id === id
        assert relay.value === value
        assert %DateTime{} = relay.timestamp
      end
    end
  end
end
