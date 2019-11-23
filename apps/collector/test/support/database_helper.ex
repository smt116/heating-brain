defmodule Collector.DatabaseHelper do
  @moduledoc false

  def clear_measurements_table do
    Collector.Measurement
    |> :mnesia.dirty_all_keys()
    |> Enum.each(& :mnesia.dirty_delete({Collector.Measurement, &1}))
  end
end
