defmodule InterfaceWeb.DashboardLive do
  use Phoenix.LiveView

  alias Collector.Measurement
  alias Collector.RelayState

  def mount(_params, _session, socket) do
    :ok = Interface.subscribe_to_storage()

    socket =
      socket
      |> assign(:sensors, [])
      |> assign(:relays, [])

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(InterfaceWeb.DashboardView, "dashboard.html", assigns)
  end

  def handle_info({:new_record, %Measurement{} = m}, socket) do
    {:noreply, update(socket, :sensors, &Keyword.put(&1, m.id, m))}
  end

  def handle_info({:new_record, %RelayState{} = r}, socket) do
    {:noreply, update(socket, :relays, &Keyword.put(&1, r.label, r))}
  end
end
