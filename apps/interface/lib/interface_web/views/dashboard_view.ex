defmodule InterfaceWeb.DashboardView do
  use InterfaceWeb, :view

  defdelegate sensor_label(id), to: Interface
end
