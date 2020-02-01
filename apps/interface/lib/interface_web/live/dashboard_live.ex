defmodule InterfaceWeb.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  import DateTime, only: [to_time: 1]

  import Interface,
    only: [
      relays_states: 1,
      sensors_chart_data: 0,
      subscribe_to_storage: 0
    ]

  alias Collector.Measurement
  alias Collector.RelayState

  def mount(_params, _session, socket) do
    :ok = subscribe_to_storage()
    relays = Enum.map(relays_states(60), fn {_, list} -> Enum.fetch!(list, -1) end)

    socket =
      socket
      |> assign(:data, sensors_chart_data())
      |> assign(:relays, relays)

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(InterfaceWeb.DashboardView, "dashboard.html", assigns)
  end

  def handle_info({:new_record, %Measurement{} = m}, socket) do
    socket =
      update(socket, :data, fn sensors ->
        Keyword.update!(sensors, m.id, fn {_, data} -> {m, data} end)
      end)

    {:noreply, socket}
  end

  def handle_info({:new_record, %RelayState{} = r}, socket) do
    {:noreply, update(socket, :relays, &Keyword.put(&1, r.id, {r.timestamp, r.value}))}
    {:noreply, socket}
  end
end
