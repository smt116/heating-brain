defmodule Collector.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnitProperties

      alias Collector.DatabaseHelper
      alias Collector.FilesystemMock
      alias Collector.Generators
    end
  end

  setup do
    Collector.DatabaseHelper.clear_tables()
    :ok = Collector.FilesystemMock.reset()

    :ok
  end
end
