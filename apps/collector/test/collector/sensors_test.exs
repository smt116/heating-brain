defmodule Collector.SensorsTest do
  use Collector.DataCase, async: false

  import Collector.Measurement, only: [new: 2]

  import Collector.Sensors,
    only: [
      select: 1,
      select: 2,
      select_all: 0,
      select_all: 1
    ]

  import Collector.Storage, only: [write: 1]

  describe "select/1" do
    test "fetches readings for a given sensor" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)
      obsolete = DateTime.add(now, -301, :second)

      new("28-01187615e4ff", 22.5) |> Map.put(:timestamp, now) |> write()
      new("28-01187615e4ff", 21.5) |> Map.put(:timestamp, before) |> write()
      new("28-01187615e4ff", 23.125) |> Map.put(:timestamp, obsolete) |> write()

      assert [
               {^before, 21.5},
               {^now, 22.5}
             ] = select(:"28-01187615e4ff")
    end
  end

  describe "select/2" do
    test "fetches radings within time boundary for a given sensor" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)

      new("28-01187615e4ff", 22.5) |> Map.put(:timestamp, now) |> write()
      new("28-01187615e4ff", 21.5) |> Map.put(:timestamp, before) |> write()

      assert [{^now, 22.5}] = select(:"28-01187615e4ff", 5)

      assert [
               {^before, 21.5},
               {^now, 22.5}
             ] = select(:"28-01187615e4ff", 6)
    end
  end

  describe "select_all/0" do
    test "fetches readings for all sensors" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)
      obsolete = DateTime.add(now, -301, :second)

      new("28-01187615e4ff", 22.5) |> Map.put(:timestamp, now) |> write()
      new("28-0118761f69ff", 21.5) |> Map.put(:timestamp, before) |> write()
      new("28-0118761f69ff", 23.125) |> Map.put(:timestamp, obsolete) |> write()

      assert [
               "28-01187615e4ff": [{^now, 22.5}],
               "28-0118761f69ff": [{^before, 21.5}]
             ] = select_all()
    end
  end

  describe "select_all/1" do
    test "fetches readings within time boundary for all sensors" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      before = DateTime.add(now, -5, :second)
      obsolete = DateTime.add(now, -301, :second)

      new("28-01187615e4ff", 22.5) |> Map.put(:timestamp, now) |> write()
      new("28-0118761f69ff", 21.5) |> Map.put(:timestamp, before) |> write()
      new("28-0118761f69ff", 23.125) |> Map.put(:timestamp, obsolete) |> write()

      assert [
               "28-01187615e4ff": [{^now, 22.5}],
               "28-0118761f69ff": [{^before, 21.5}]
             ] = select_all()

      assert [
               "28-01187615e4ff": [{^now, 22.5}],
               "28-0118761f69ff": [{^obsolete, 23.125}, {^before, 21.5}]
             ] = select_all(310)
    end
  end
end
