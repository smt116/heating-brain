defmodule Collector.OneWire do
  @moduledoc """
  Core logic for handling sensors connected via the 1-wire bus.
  """

  alias Collector.Measurement

  @opaque raw_id :: atom
  @type error :: String.t()
  @type label :: Measurement.id()
  @type read :: {:ok, Measurement.t()} | {:error, error}

  @handler Application.get_env(:collector, :filesystem_handler)
  @w1_bus_master1_path Application.get_env(:collector, :w1_bus_master1_path)

  @doc """
  Returns a list of all available sensors. It uses the special file from the 1-wire
  master bus directory (called `w1_master_slaves`). This file contains all ids. The
  returned value of the function is not the list of raw ids given by the underlying
  sensors' devices, but it is the list of mapped sensors' labels defined in the
  config.

  ## Examples

      iex> Collector.OneWire.sensors()
      [:foo, :bar]

  """
  @spec sensors :: list(label)
  def sensors do
    @w1_bus_master1_path
    |> Path.join("w1_master_slaves")
    |> @handler.read!()
    |> String.split()
    |> Stream.map(&String.to_atom/1)
    |> Stream.map(&to_label/1)
    |> Enum.sort()
  end

  @doc """
  Returns the temperature of a given sensor.

  ## Examples

      iex> Collector.OneWire.read(:foo)
      {:ok, %Collector.Measurement{
        timestamp: ~U[2019-10-28 07:52:26.155383Z],
        value: 23.187
      }}

      iex> Collector.OneWire.read(:bar)
      {:error, "bar sensor reported power-on reset value"}

  """
  @spec read(label) :: read
  def read(label) when is_atom(label) do
    id = to_id(label)

    id
    |> sensor_output_path()
    |> @handler.read!()
    |> extract_temperature(label)
    |> handle_result(id)
  end

  # `w1_slave` has the following format:
  #
  #     60 01 4b 46 7f ff 0c 10 14 : crc=14 YES
  #     60 01 4b 46 7f ff 0c 10 14 t=22000
  #
  # where `YES` means that the reading is not malformed and `t=22000` means that
  # the current temperature is 22°C.
  defp extract_temperature(output, id) when is_atom(id) and is_binary(output) do
    [first, second] =
      output
      |> String.trim()
      |> String.split("\n")

    if String.ends_with?(first, "YES") do
      ~r/t=(?<temperature>[-\d]+)/
      |> Regex.named_captures(second)
      |> Map.fetch!("temperature")
      |> handle_raw_temperature(id)
    else
      {:error, "#{id} sensor read failed: #{inspect(output)}"}
    end
  end

  defp handle_raw_temperature("85000", id) do
    {:error, "#{id} sensor reported power-on reset value"}
  end

  defp handle_raw_temperature(raw_temperature, id) do
    case Integer.parse(raw_temperature) do
      {value, ""} ->
        {:ok, value / 1000}

      :error ->
        {
          :error,
          "#{id} sensor reported unparseable value: #{raw_temperature}"
        }
    end
  end

  defp handle_result({:ok, value}, id) do
    {:ok, to_label(id) |> Measurement.new(value)}
  end

  defp handle_result({:error, _} = result, _id), do: result

  # The 1-wire master bus directory includes subdirectories for all conencted
  # sensors. Each such subdirectory includes `w1_slave` file that can be used
  # for fetching sensor value.
  defp sensor_output_path(id) when is_atom(id) do
    @w1_bus_master1_path
    |> Path.join(to_string(id))
    |> Path.join("w1_slave")
  end

  # Translates the sensor label into the identifier. See `label/1` comment for
  # details.
  @spec to_id(label) :: raw_id
  defp to_id(label) when is_atom(label) do
    Application.get_env(:collector, :sensors_map)
    |> Enum.map(fn {id, label, _, _} -> {label, id} end)
    |> Keyword.get(label, label)
  end

  # Translates the sensor identifier into the human-readable label (if available).
  # Labels are defined in the config and they look like `:bathroom`. Those atoms
  # are treated as the `id` by the rest of the application. On the other hand,
  # `raw_id` here refers to the identifier of the sensor given by the 1-wire master
  # bus.
  @spec to_label(raw_id) :: label
  defp to_label(raw_id) when is_atom(raw_id) do
    Application.get_env(:collector, :sensors_map)
    |> Enum.map(fn {id, label, _, _} -> {id, label} end)
    |> Keyword.get(raw_id, raw_id)
  end
end
