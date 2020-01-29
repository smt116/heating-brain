defmodule Collector do
  @moduledoc """
  The interface for interacting with sensors and relays.
  """

  alias Collector.OneWireWorker
  alias Collector.Relays
  alias Collector.Sensors
  alias Collector.Storage

  defdelegate current_sensors_readings, to: OneWireWorker, as: :read_all

  defdelegate current_relays_states, to: Relays, as: :read_all
  defdelegate relays_states, to: Relays, as: :select_all
  defdelegate relays_states(boundary), to: Relays, as: :select_all

  defdelegate expected_sensors_values, to: Sensors, as: :expected_values
  defdelegate sensors_readings, to: Sensors, as: :select_all
  defdelegate sensors_readings(boundary), to: Sensors, as: :select_all

  defdelegate subscribe, to: Storage
  defdelegate unsubscribe(pid), to: Storage
end
