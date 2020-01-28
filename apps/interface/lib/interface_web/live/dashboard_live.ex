defmodule InterfaceWeb.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  import DateTime, only: [to_time: 1]

  alias Collector.Measurement
  alias Collector.RelayState

  def mount(_params, _session, socket) do
    :ok = Interface.subscribe_to_storage()

    sensors =
      Interface.all_sensors_readings(43_200)
      |> Enum.map(fn {id, readings} ->
        {last_read_at, current_value} = Enum.max_by(readings, &elem(&1, 0))
        {labels, dataset} = Enum.unzip(readings)

        {
          Interface.sensor_label(id),
          {
            {to_time(last_read_at), current_value},
            Enum.drop(dataset, -1),
            Enum.map(labels, &to_time/1)
          }
        }
      end)

    relays =
      Interface.all_relays_states()
      |> Enum.map(fn {id, states} ->
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
    socket =
      update(socket, :sensors, fn sensors ->
        label = Interface.sensor_label(m.id)

        Keyword.update!(sensors, label, fn {_, dataset, labels} ->
          {{to_time(m.timestamp), m.value}, dataset, labels}
        end)
      end)

    {:noreply, socket}
  end

  def handle_info({:new_record, %RelayState{} = r}, socket) do
    {:noreply, update(socket, :relays, &Keyword.put(&1, r.id, {r.timestamp, r.value}))}
    {:noreply, socket}
  end
end
