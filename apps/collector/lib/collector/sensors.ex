defmodule Collector.Sensors do
  @moduledoc """
  The interface for sensors. It allows checking current values (via the filesystem)
  and reading historical data from the storage.
  """

  alias Collector.Measurement
  alias Collector.Storage

  @type simplified_measurement :: {Measurement.id(), list({DateTime.t(), value})}
  @type timestamp :: DateTime.t()
  @type value :: Measurement.value()

  @handler Application.get_env(:collector, :filesystem_handler)
  @w1_bus_master1_path Application.get_env(:collector, :w1_bus_master1_path)

  @doc """
  Reads latest measurements.

  ## Examples

      iex> Collector.Sensors.current()
      [
        "28-01187615e4ff": {~U[2019-12-11 21:51:14Z], 22.0},
        "28-0118761f69ff": {~U[2019-12-11 21:51:14Z], 22.0}
      ]

  """
  @spec current :: [simplified_measurement]
  def current do
    # In fact, it should be :mnesia.last with ordered_set table but this kind of
    # semantic is not supported for disc_only_copies.
    #
    # FIXME: use disc_copies semantic
    #        http://erlang.org/doc/man/mnesia.html#description
    fn %{id: id, value: value, timestamp: timestamp}, acc ->
      acc
      |> Keyword.put_new(id, nil)
      |> Keyword.get_and_update(id, &{&1, newer(&1, {timestamp, value})})
      |> elem(1)
      |> Enum.reject(fn {_id, value} -> is_nil(value) end)
    end
    |> Storage.read(Measurement)
    |> Enum.sort()
  end

  @doc """
  Reads current values from the file system via the 1-wire master bus. It does not
  interact with the database.

  ## Examples

      iex> Collector.Sensors.read_all()
      [
        %Collector.Measurement{
          id: :"28-0118761f69ff",
          timestamp: ~U[2019-10-28 07:52:26.155383Z],
          value: 23.187
        },
        %Collector.Measurement{
          id: :"28-01187615e4ff",
          timestamp: ~U[2019-10-28 07:52:26.155832Z],
          value: 24.011
        }
      ]

  """
  @spec read_all :: list(Measurement.t())
  def read_all do
    w1_sensors()
    |> Stream.map(&{&1, sensor_output_path(&1)})
    |> Stream.map(fn {id, path} -> {id, @handler.read!(path)} end)
    |> Stream.map(fn {id, output} -> {id, extract_temperature(output)} end)
    |> Stream.reject(fn {_, check} -> check === :error end)
    |> Stream.map(fn {id, {:ok, value}} -> {id, Integer.parse(value)} end)
    |> Enum.map(fn {id, {int, ""}} -> Measurement.new(id, int / 1000) end)
  end

  @doc """
  Reads measurements from database. It accepts a function that can be used to
  filter data.

  ## Examples

      iex> Collector.Sensors.get()
      [
        "28-0118761f69ff": [
          {~U[2019-10-28 07:46:56Z], 21.875},
          {~U[2019-10-28 07:47:13Z], 21.875}
        ],
        "28-01187615e4ff": [
          {~U[2019-10-28 07:46:55Z], 23.687},
          {~U[2019-10-28 07:47:12Z], 23.437}
        ]
      ]

     iex> Collector.Sensors.get(& &1.id == :"28-0118761f69ff")
      [
        "28-0118761f69ff": [
          {~U[2019-10-28 07:46:56Z], 21.875},
          {~U[2019-10-28 07:47:13Z], 21.875}
        ]
      ]

  """
  # FIXME: support get_and_update function as the argument and extract this (as duplicated in relasy)
  @spec get((Measurement.t() -> boolean)) :: [simplified_measurement]
  def get(f \\ &(&1 === &1)) when is_function(f) do
    fn %{id: id, value: value, timestamp: timestamp} = item, acc ->
      if f.(item) do
        acc
        |> Keyword.put_new(id, [])
        |> Keyword.get_and_update(id, &{&1, [{timestamp, value} | &1]})
        |> elem(1)
      else
        acc
      end
    end
    |> Storage.read(Measurement)
    |> Enum.map(fn {id, readings} -> {id, Enum.sort(readings)} end)
  end

  @doc """
  Reads measurements made in last N seconds from database.
  """
  @spec latest(pos_integer) :: [{atom, list(Measurement.t())}]
  def latest(within \\ 600) when is_integer(within) and within > 0 do
    time_boundary =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.add(-within, :second)

    get(&(DateTime.compare(&1.timestamp, time_boundary) === :gt))
  end

  # The 1-wire master bus directory includes `w1_master_slaves` file which
  # stores all connected sensors' ids.
  defp w1_sensors do
    @w1_bus_master1_path
    |> Path.join("w1_master_slaves")
    |> @handler.read!()
    |> String.split()
  end

  # The 1-wire master bus directory includes subdirectories for all conencted
  # sensors. Each such subdirectory includes `w1_slave` file that can be used
  # for fetching sensor value.
  defp sensor_output_path(id) when is_binary(id) do
    @w1_bus_master1_path
    |> Path.join(id)
    |> Path.join("w1_slave")
  end

  # `w1_slave` has the following format:
  #
  #     60 01 4b 46 7f ff 0c 10 14 : crc=14 YES
  #     60 01 4b 46 7f ff 0c 10 14 t=22000
  #
  # where `YES` means that the reading is not malformed and `t=22000` means that
  # the current temperature is 22°C.
  defp extract_temperature(output) when is_binary(output) do
    [first, second] =
      output
      |> String.trim()
      |> String.split("\n")

    if String.ends_with?(first, "YES") do
      raw_temperature =
        ~r/t=(?<temperature>[-\d]+)/
        |> Regex.named_captures(second)
        |> Map.fetch!("temperature")

      {:ok, raw_temperature}
    else
      :error
    end
  end

  # FIXME: duplicated in `Relays` module
  @spec newer({timestamp, value}, {timestamp, value}) :: {timestamp, value}
  defp newer(nil, candidate), do: candidate
  defp newer({a, _} = current, {b, _}) when a >= b, do: current
  defp newer(_current, candidate), do: candidate
end
