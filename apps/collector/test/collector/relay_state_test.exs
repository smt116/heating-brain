defmodule Collector.RelayStateTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest String.Chars.Collector.RelayState

  import Collector.RelayState, only: [new: 2]

  alias Collector.RelayState

  describe "new/2" do
    property "converts attributes into the struct with timestamp" do
      check all label <- atom(:alphanumeric),
                value <- boolean() do
        assert %RelayState{} = relay = new(label, value)

        assert relay.label === label
        assert relay.value === value
        assert %DateTime{} = relay.timestamp
      end
    end
  end
end
