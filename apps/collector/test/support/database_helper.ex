defmodule Collector.DatabaseHelper do
  @moduledoc false

  def clear_measurements_table do
    {:atomic, :ok} =
      fn ->
        Collector.Measurement
        |> :mnesia.all_keys()
        |> Enum.each(& :mnesia.delete({Collector.Measurement, &1}))
      end
      |> :mnesia.transaction()
  end
end
