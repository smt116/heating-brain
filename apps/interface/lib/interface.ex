defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe

  defdelegate sensors_readings(within), to: Collector
  defdelegate relays_states, to: Collector
end
