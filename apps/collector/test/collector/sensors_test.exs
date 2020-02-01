defmodule Collector.SensorsTest do
  use Collector.DataCase, async: false

  import Collector.Measurement, only: [new: 2]

  import Collector.Sensors,
    only: [
      select: 1,
      select: 2
    ]

  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement

  describe "select/1" do
    test "fetches readings within time boundary for all sensors" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)
      obsolete = DateTime.add(now, -301, :second)

      new(:bathroom, 22.5) |> Map.put(:timestamp, now) |> write()
      new(:bathroom, 21.5) |> Map.put(:timestamp, before) |> write()
      new(:unknown, 23.125) |> Map.put(:timestamp, obsolete) |> write()

      assert [
               bathroom: [
                 %Measurement{id: :bathroom, value: 21.5, timestamp: ^before},
                 %Measurement{id: :bathroom, value: 22.5, timestamp: ^now}
               ],
               unknown: [
                 %Measurement{id: :unknown, value: 23.125, timestamp: ^obsolete}
               ]
             ] = select(310)

      assert [
               bathroom: [
                 %Measurement{id: :bathroom, value: 22.5, timestamp: ^now}
               ]
             ] = select(4)
    end
  end

  describe "select/2" do
    test "fetches readings within time boundary for a given sensor" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)

      new(:case, 22.5) |> Map.put(:timestamp, now) |> write()
      new(:case, 21.5) |> Map.put(:timestamp, before) |> write()

      assert [
               %Measurement{id: :case, value: 22.5}
             ] = select(:case, 5)

      assert [
               %Measurement{id: :case, value: 21.5, timestamp: ^before},
               %Measurement{id: :case, value: 22.5, timestamp: ^now}
             ] = select(:case, 6)
    end
  end
end
