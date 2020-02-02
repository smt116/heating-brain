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
  defdelegate relays_states(within), to: Relays, as: :select
  defdelegate relays_states(id, within), to: Relays, as: :select

  defdelegate relay_id_to_sensor_id(id), to: Sensors, as: :to_sensor_id
  defdelegate sensor_id_to_relay_id(id), to: Sensors, as: :to_relay_id
  defdelegate sensors_readings(id, within), to: Sensors, as: :select
  defdelegate sensors_readings(within), to: Sensors, as: :select

  defdelegate subscribe, to: Storage
  defdelegate unsubscribe(pid), to: Storage
end
