defmodule Collector.OneWire do
  @moduledoc """
  Core logic for handling sensors connected via the 1-wire bus.
  """

  alias Collector.Measurement

  @type error :: String.t()
  @type id :: Measurement.id()
  @type label :: Measurement.label()
  @type read :: {:ok, Measurement.t()} | {:error, error}
  @type temperature :: float

  @handler Application.get_env(:collector, :filesystem_handler)
  @w1_bus_master1_path Application.get_env(:collector, :w1_bus_master1_path)

  @doc """
  Translates the sensor identifier into the human-readable label (if available).
  """
  @spec label(id) :: label
  def label(id) when is_atom(id) do
    Application.get_env(:collector, :sensors_map)
    |> Enum.map(fn {i, label, _, _} -> {i, label} end)
    |> Keyword.get(id, id)
  end

  @doc """
  Returns a list of all available sensors. It uses the special file from the 1-wire
  master bus directory called `w1_master_slaves`. This file contains all ids.

  ## Examples

      iex> Collector.OneWire.sensors()
      [:foo, :bar]

  """
  @spec sensors :: list(id)
  def sensors do
    @w1_bus_master1_path
    |> Path.join("w1_master_slaves")
    |> @handler.read!()
    |> String.split()
    |> Stream.map(&String.to_atom/1)
    |> Enum.sort()
  end

  @doc """
  Returns the value of a given sensor.

  ## Examples

      iex> Collector.OneWire.read(:foo)
      {:ok, %Collector.Measurement{
        id: :"28-0118761f69ff",
        timestamp: ~U[2019-10-28 07:52:26.155383Z],
        value: 23.187
      }}

      iex> Collector.OneWire.read(:bar)
      {:error, "bar reported power-on reset value"}

  """
  @spec read(id) :: read
  def read(id) when is_atom(id) do
    id
    |> sensor_output_path()
    |> @handler.read!()
    |> extract_temperature(id)
    |> handle_result(id)
  end

  # The 1-wire master bus directory includes subdirectories for all conencted
  # sensors. Each such subdirectory includes `w1_slave` file that can be used
  # for fetching sensor value.
  defp sensor_output_path(id) when is_atom(id) do
    @w1_bus_master1_path
    |> Path.join(to_string(id))
    |> Path.join("w1_slave")
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
      {:error, "#{id} read failed: #{inspect(output)}"}
    end
  end

  defp handle_raw_temperature("85000", id) do
    {:error, "#{id} reported power-on reset value"}
  end

  defp handle_raw_temperature(raw_temperature, id) do
    case Integer.parse(raw_temperature) do
      {value, ""} -> {:ok, value / 1000}
      :error -> {:error, "#{id} reported unparseable value: #{raw_temperature}"}
    end
  end

  defp handle_result({:ok, value}, id), do: {:ok, Measurement.new(id, value)}
  defp handle_result({:error, _} = result, _id), do: result
end
