defmodule Collector do
  @moduledoc """
  The interface for interacting with sensors and relays.
  """

  alias Collector.OneWire
  alias Collector.OneWireWorker
  alias Collector.Relays
  alias Collector.Sensors
  alias Collector.Storage

  defdelegate current_sensors_readings, to: OneWireWorker, as: :read_all
  defdelegate sensor_label(id), to: OneWire, as: :label

  defdelegate current_relays_states, to: Relays, as: :read_all
  defdelegate relay_states(id), to: Relays, as: :select
  defdelegate relay_states(id, boundary), to: Relays, as: :select
  defdelegate all_relays_states, to: Relays, as: :select_all
  defdelegate all_relays_states(boundary), to: Relays, as: :select_all

  defdelegate sensor_readings(id), to: Sensors, as: :select
  defdelegate sensor_readings(id, boundary), to: Sensors, as: :select
  defdelegate all_sensors_readings, to: Sensors, as: :select_all
  defdelegate all_sensors_readings(boundary), to: Sensors, as: :select_all

  defdelegate subscribe, to: Storage
  defdelegate unsubscribe(pid), to: Storage
end
