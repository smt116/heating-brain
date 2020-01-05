defmodule Collector do
  @moduledoc """
  The interface for interacting with sensors and relays.
  """

  alias Collector.Relays
  alias Collector.Sensors

  defdelegate fs_put_relay_state(relay_state), to: Relays, as: :put_state
  defdelegate fs_relays_states, to: Relays, as: :read_all
  defdelegate relays_states, to: Relays, as: :current

  defdelegate fs_read_sensors, to: Sensors, as: :read_all
  defdelegate get_sensor(f), to: Sensors, as: :get
  defdelegate get_sensor, to: Sensors, as: :get
  defdelegate latest_sensors_readings(within), to: Sensors, as: :latest
  defdelegate latest_sensors_readings, to: Sensors, as: :latest
  defdelegate sensors_values, to: Sensors, as: :current

  defdelegate subscribe, to: Collector.Storage
  defdelegate unsubscribe(pid), to: Collector.Storage
end
