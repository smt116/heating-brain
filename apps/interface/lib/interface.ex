defmodule Interface do
  @moduledoc """
  Core logic for the interface.
  """

  defdelegate sensor_label(id), to: Collector
  defdelegate subscribe_to_storage, to: Collector, as: :subscribe
  defdelegate unsubscribe_from_storage(pid), to: Collector, as: :unsubscribe
end
