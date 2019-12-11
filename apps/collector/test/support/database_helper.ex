defmodule Collector.DatabaseHelper do
  @moduledoc false

  def clear_tables do
    Enum.each(
      [
        Collector.Measurement,
        Collector.RelayState
      ],
      fn table ->
        fn ->
          table
          |> :mnesia.all_keys()
          |> Enum.each(&:mnesia.delete({table, &1}))
        end
        |> :mnesia.transaction()
      end
    )
  end
end
