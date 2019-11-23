defmodule Collector.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnitProperties

      alias Collector.DatabaseHelper
      alias Collector.FilesystemGenerator
      alias Collector.Generators
    end
  end

  setup_all _tags do
    Collector.DatabaseHelper.clear_measurements_table()
    {:ok, _pid} = Collector.FilesystemGenerator.start_link()

    :ok
  end

  setup do
    Collector.DatabaseHelper.clear_measurements_table()

    :ok
  end
end
