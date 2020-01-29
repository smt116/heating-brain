defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe

  defdelegate expected_sensors_values, to: Collector
  defdelegate relays_states, to: Collector
  defdelegate sensors_readings(within), to: Collector
end
