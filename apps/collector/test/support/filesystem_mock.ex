defmodule Collector.FilesystemMock do
  @moduledoc """
  Mocks the GPIO and 1-wire bus filesystem for development and test purposes.
  """

  use GenServer

  @gpio_path Application.get_env(:collector, :gpio_base_path)
  @gpio_export_path Path.join([@gpio_path, "export"])
  @relays_map Application.get_env(:collector, :relays_map)
  @sensors_map Application.get_env(:collector, :sensors_map)
  @w1_bus_path Application.get_env(:collector, :w1_bus_master1_path)
  @w1_slaves_path Path.join([@w1_bus_path, "w1_master_slaves"])

  @sensor_output "60 01 4b 14 : crc=14 YES\n7f ff 0c 10 14 t=22000\n"
  @sensor_path_prefix_length String.length("/sys/bus/w1/devices/w1_bus_master1") + 1
  @sensor_path_suffix_length String.length("/w1_slave") + 1

  @impl true
  def init(_state) do
    paths =
      [
        [
          {@gpio_path, :directory},
          {@gpio_export_path, :driver},
          {@w1_bus_path, :directory},
          {@w1_slaves_path, {:file, ""}}
        ],
        Enum.map(@relays_map, &gpio_paths/1),
        Enum.map(@sensors_map, &sensor_paths/1)
      ]
      |> List.flatten()
      |> Enum.map(fn {path, value} -> {String.to_atom(path), value} end)

    state = Keyword.put(paths, String.to_atom(@w1_slaves_path), w1_slaves_content(paths))

    {:ok, state}
  end

  @impl true
  def handle_call(:clear, _pid, _state) do
    paths =
      Enum.map(
        [
          {@gpio_path, :directory},
          {@gpio_export_path, :driver},
          {@w1_bus_path, :directory},
          {@w1_slaves_path, {:file, ""}}
        ],
        fn {path, value} -> {String.to_atom(path), value} end
      )

    {:reply, :ok, paths}
  end

  def handle_call({:dir?, path}, _pid, state) do
    result =
      case Keyword.get(state, path) do
        {_path, :directory} -> true
        _ -> false
      end

    {:reply, result, state}
  end

  def handle_call({:mkdir!, path}, _pid, state) do
    {:reply, :ok, Keyword.put(state, path, :directory)}
  end

  def handle_call(:paths, _pid, state) do
    paths =
      state
      |> Stream.map(&elem(&1, 0))
      |> Enum.map(&to_string/1)

    {:reply, paths, state}
  end

  def handle_call({:read!, path}, _pid, state) do
    value = Keyword.get(state, path)

    if is_nil(value) do
      {:reply, :error, state}
    else
      {:reply, {:ok, value}, state}
    end
  end

  def handle_call(:refresh_w1_slaves_content, _pid, state) do
    new_state =
      Keyword.put(
        state,
        String.to_atom(@w1_slaves_path),
        w1_slaves_content(state)
      )

    {:reply, :ok, new_state}
  end

  def handle_call({:write!, path, content}, _pid, state) do
    {:reply, :ok, Keyword.put(state, path, {:file, content})}
  end

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  def dir?(path) when is_binary(path) do
    GenServer.call(__MODULE__, {:dir?, String.to_atom(path)})
  end

  def mkdir!(path) when is_binary(path) do
    GenServer.call(__MODULE__, {:mkdir!, String.to_atom(path)})
  end

  def paths do
    GenServer.call(__MODULE__, :paths)
  end

  def read!(path) when is_binary(path) do
    case GenServer.call(__MODULE__, {:read!, String.to_atom(path)}) do
      {:ok, {:file, content}} ->
        content

      :error ->
        raise("could not read file \"#{path}\": no such file or directory")
    end
  end

  def reset do
    :ok = clear()
    :ok = Collector.Relays.setup_all()
  end

  def set_sensor(label, val, opts \\ []) when is_atom(label) and is_float(val) do
    id =
      Application.get_env(:collector, :sensors_map)
      |> Enum.find({label, label}, &(elem(&1, 1) === label))
      |> elem(0)

    content =
      @sensor_output
      |> String.replace("22000", trunc(val * 1000) |> to_string())
      |> String.replace("YES", if(opts[:malformed], do: "NO", else: "YES"))

    id
    |> sensor_paths(content)
    |> Enum.each(&create/1)

    GenServer.call(__MODULE__, :refresh_w1_slaves_content)
  end

  def set_relay(id, value) when is_atom(id) and is_boolean(value) do
    {_, pin, direction, _} = Enum.find(@relays_map, fn {l, _, _, _} -> id == l end)
    raw_value = if(value, do: "1\n", else: "0\n")

    pin
    |> gpio_paths(direction, raw_value)
    |> Enum.each(&create/1)
  end

  def write!(@gpio_export_path, pin) when is_binary(pin) do
    pin
    |> gpio_paths()
    |> Enum.each(&create/1)
  end

  def write!(path, content) when is_binary(path) and is_binary(content) do
    GenServer.call(__MODULE__, {:write!, String.to_atom(path), content})
  end

  defp create({path, :directory}), do: mkdir!(path)
  defp create({path, {:file, content}}), do: write!(path, content)

  defp gpio_paths({_, pin, direction, _}), do: gpio_paths(pin, direction)

  defp gpio_paths(pin, direction \\ "out", value \\ "0\n")
  defp gpio_paths(p, d, v) when is_number(p), do: to_string(p) |> gpio_paths(d, v)

  defp gpio_paths(p, d, v) when is_binary(p) and is_binary(d) and is_binary(v) do
    [
      {Path.join([@gpio_path, "gpio#{p}"]), :directory},
      {Path.join([@gpio_path, "gpio#{p}", "value"]), {:file, v}},
      {Path.join([@gpio_path, "gpio#{p}", "direction"]), {:file, d <> "\n"}}
    ]
  end

  defp is_sensor_path(p) when is_atom(p), do: to_string(p) |> is_sensor_path()

  defp is_sensor_path(path) do
    String.starts_with?(path, @w1_bus_path) && String.ends_with?(path, "/w1_slave")
  end

  defp path_to_sensor_id(path) do
    String.slice(path, @sensor_path_prefix_length..-@sensor_path_suffix_length)
  end

  defp sensor_paths(id, content \\ @sensor_output)
  defp sensor_paths({id, _, _, _}, content), do: sensor_paths(id, content)
  defp sensor_paths(id, c) when is_atom(id), do: to_string(id) |> sensor_paths(c)

  defp sensor_paths(id, content) when is_binary(id) and is_binary(content) do
    [
      {Path.join([@w1_bus_path, id]), :directory},
      {Path.join([@w1_bus_path, id, "w1_slave"]), {:file, content}}
    ]
  end

  defp w1_slaves_content(paths) do
    {
      :file,
      (paths
       |> Stream.filter(fn {path, _} -> is_sensor_path(path) end)
       |> Stream.filter(fn {_, v} -> is_tuple(v) && elem(v, 0) === :file end)
       |> Stream.map(fn {path, _} -> to_string(path) end)
       |> Stream.map(&path_to_sensor_id/1)
       |> Enum.join("\n")) <> "\n"
    }
  end
end
