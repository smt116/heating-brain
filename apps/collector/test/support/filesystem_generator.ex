defmodule Collector.FilesystemGenerator do
  @moduledoc """
  Helper for generating sensors related files for testing purposes.
  """

  use GenServer

  alias Collector.Measurement

  @opaque state :: [one_wire_sensors: [{Measurement.id(), Measurement.value()}]]

  @fixtures_path Path.join([__ENV__.file, "..", "..", "fixtures"])
  @filesystem_path Path.join(@fixtures_path, "sys") |> Path.expand()
  @devices_path Path.join([@filesystem_path, "bus", "w1", "devices"])
  @w1_bus_master1_path Path.join([@devices_path, "w1_bus_master1"])
  @w1_master_slaves_path Path.join([@w1_bus_master1_path, "w1_master_slaves"])

  @impl true
  def init(state) do
    File.rm_rf!(@filesystem_path)
    File.mkdir_p!(@w1_bus_master1_path)
    File.touch!(@w1_master_slaves_path)

    {:ok, state}
  end

  @impl true
  def handle_call(:clear_sensors, _pid, state) do
    Enum.each(state[:one_wire_sensors], fn {id, _value} ->
      Path.join(@w1_bus_master1_path, to_string(id)) |> File.rm_rf!()
    end)

    File.write!(@w1_master_slaves_path, "")

    {:reply, :ok, put_in(state, [:one_wire_sensors], [])}
  end

  @impl true
  def handle_call({:set_sensor, id, value, opts}, _pid, state) do
    update_sensor_filesystem(id, value, opts)

    {:reply, :ok, put_in(state, [:one_wire_sensors, id], value)}
  end

  def clear_sensors do
    :ok = GenServer.call(__MODULE__, :clear_sensors)
  end

  def start_link(state \\ [one_wire_sensors: []]) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def set_sensor(id, val, opts \\ []) when is_atom(id) and is_float(val) do
    :ok = GenServer.call(__MODULE__, {:set_sensor, id, val, opts})
  end

  defp update_sensor_filesystem(id, value, opts) do
    raw_id = to_string(id)
    sensor_dir_path = Path.join(@w1_bus_master1_path, raw_id)
    sensor_file_path = Path.join(sensor_dir_path, "w1_slave")
    raw_value = trunc(value * 1000) |> to_string()
    raw_malformed = if opts[:malformed], do: "NO", else: "YES"

    File.mkdir_p!(sensor_dir_path)
    File.write!(sensor_file_path, "#{raw_malformed}\nt=#{raw_value}")

    unless File.read!(@w1_master_slaves_path) |> String.contains?(raw_id) do
      File.write!(@w1_master_slaves_path, raw_id <> "\n", [:append])
    end
  end
end
