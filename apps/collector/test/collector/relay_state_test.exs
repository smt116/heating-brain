defmodule Collector.RelayStateTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest String.Chars.Collector.RelayState

  import Collector.RelayState, only: [new: 2]

  alias Collector.RelayState

  describe "new/2" do
    property "converts attributes into the struct with timestamp" do
      check all id <- atom(:alphanumeric),
                value <- boolean() do
        assert %RelayState{} = relay = new(id, value)

        assert relay.id === id
        assert relay.value === value
        assert %DateTime{} = relay.timestamp
      end
    end
  end
end
