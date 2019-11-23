defmodule Collector do
  @moduledoc """
  The interface for interacting with sensors and relays.
  """

  defdelegate get, to: Collector.Sensors
  defdelegate get(f), to: Collector.Sensors
  defdelegate latest, to: Collector.Sensors
  defdelegate latest(within), to: Collector.Sensors
  defdelegate read_all, to: Collector.Sensors
end
