defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  # FIXME: pass translated labels to interface
  defdelegate sensor_label(id), to: Collector
  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe

  defdelegate all_sensors_readings, to: Collector
  defdelegate all_relays_states, to: Collector
end
