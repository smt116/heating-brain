defmodule InterfaceWeb.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  import Interface,
    only: [
      relay_id_to_sensor_id: 1,
      sensors_chart_data: 0,
      subscribe_to_storage: 0
    ]

  alias Collector.Measurement
  alias Collector.RelayState

  def mount(_params, _session, socket) do
    :ok = subscribe_to_storage()

    socket = assign(socket, :data, sensors_chart_data())

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(InterfaceWeb.DashboardView, "dashboard.html", assigns)
  end

  def handle_info({:new_record, %Measurement{id: :pipe_in} = pi}, socket) do
    socket =
      update(socket, :data, fn sensors ->
        Enum.map(sensors, fn {id, {m, _, r, data}} ->
          {id, {m, pi, r, data}}
        end)
      end)

    {:noreply, socket}
  end

  def handle_info({:new_record, %Measurement{} = m}, socket) do
    socket =
      update(socket, :data, fn sensors ->
        Keyword.update!(sensors, m.id, fn
          {_, pi, nil, data} -> {m, pi, nil, data}
          {_, pi, r, data} -> {m, pi, r, data}
        end)
      end)

    {:noreply, socket}
  end

  def handle_info({:new_record, %RelayState{} = r}, socket) do
    socket =
      update(socket, :data, fn sensors ->
        m_id = relay_id_to_sensor_id(r.id)

        if is_nil(m_id) do
          sensors
        else
          Keyword.update!(sensors, m_id, fn {m, _, data} -> {m, r, data} end)
        end
      end)

    {:noreply, socket}
  end
end
