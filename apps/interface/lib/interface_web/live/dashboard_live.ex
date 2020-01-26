defmodule InterfaceWeb.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Collector.Measurement
  alias Collector.RelayState

  def mount(_params, _session, socket) do
    :ok = Interface.subscribe_to_storage()

    sensors =
      Interface.all_sensors_readings() |> Enum.map(fn {id, readings} ->
        {id, Enum.max_by(readings, &elem(&1, 0))}
      end)

    relays =
      Interface.all_relays_states() |> Enum.map(fn {id, states} ->
        {id, Enum.max_by(states, &elem(&1, 0))}
      end)

    socket =
      socket
      |> assign(:sensors, sensors)
      |> assign(:relays, relays)

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(InterfaceWeb.DashboardView, "dashboard.html", assigns)
  end

  def handle_info({:new_record, %Measurement{} = m}, socket) do
    {:noreply, update(socket, :sensors, &Keyword.put(&1, m.id, {m.timestamp, m.value}))}
  end

  def handle_info({:new_record, %RelayState{} = r}, socket) do
    {:noreply, update(socket, :relays, &Keyword.put(&1, r.label, {r.timestamp, r.value}))}
  end
end
