defmodule Collector.Sensors do
  @moduledoc """
  The interface for accessing sensors' readings from the storage. It does not
  interfere with the 1-wire filesystem, and thus the "current values".
  """

  alias Collector.Measurement
  alias Collector.Storage

  @type id :: Measurement.id()
  @type label :: Measurement.label()
  @type simplified_readings :: list({timestamp, value})
  @type timestamp :: DateTime.t()
  @type value :: Measurement.value()

  @doc """
  Returns expected values for given sensor labels.

  ## Examples

      iex> Collector.Sensors.expected_values()
      [
        bathroom: 23.5,
        case: nil,
        living_room: 21.0
      ]

  """
  @spec expected_values :: list({label, value})
  def expected_values do
    Application.get_env(:collector, :sensors_map)
    |> Stream.map(fn {_, label, _, expected_value} -> {label, expected_value} end)
    |> Enum.sort()
  end

  @doc """
  Returns readings for a given sensor. The results are limitated to those that were
  made within last N seconds (default: 5 minutes).

  ## Examples

      iex> Collector.Sensors.select(:"28-01187615e4ff", 90)
      [
        {~U[2020-01-26 08:40:48Z], 24.0}
      ]

      iex> Collector.Sensors.select(:"28-01187615e4ff")
      [
        {~U[2020-01-26 08:37:38Z], 22.0},
        {~U[2020-01-26 08:38:58Z], 21.0},
        {~U[2020-01-26 08:39:58Z], 22.5},
        {~U[2020-01-26 08:40:48Z], 24.0}
      ]

  """
  @spec select(id, timestamp | pos_integer) :: simplified_readings
  def select(id, within \\ 300)

  def select(id, within) when is_atom(id) and is_integer(within) and within > 0 do
    select(id, to_datetime(within))
  end

  def select(id, %DateTime{} = since) when is_atom(id) do
    Storage.select(Measurement, id, since)
  end

  @doc """
  Returns readings for all, defined sensor. The results are limitated to those
  readings that were made within last N seconds (default: 5 minutes).

  ## Examples

      iex> Collector.Sensors.select_all(90)
      [
        case: [
          {~U[2020-01-26 08:40:38Z], 22.0},
          {~U[2020-01-26 08:40:48Z], 21.0}
        ],
        living_room: [
          {~U[2020-01-26 08:40:48Z], 24.0}
        ],
        pipe: [
          {~U[2020-01-26 08:40:38Z], 22.0},
        ]
      ]

      iex> Collector.Sensors.select_all()
      [
        case: [
          {~U[2020-01-26 08:40:38Z], 22.0},
          {~U[2020-01-26 08:40:48Z], 21.0}
        ],
        living_room: [
          {~U[2020-01-26 08:37:38Z], 22.0},
          {~U[2020-01-26 08:38:58Z], 21.0},
          {~U[2020-01-26 08:39:58Z], 22.5},
          {~U[2020-01-26 08:40:48Z], 24.0}
        ],
        pipe: [
          {~U[2020-01-26 08:40:38Z], 22.0},
          {~U[2020-01-26 08:40:48Z], 22.2}
        ]
      ]

  """
  @spec select_all(timestamp | pos_integer) :: list({id, simplified_readings})
  def select_all(within \\ 300)

  def select_all(within) when is_integer(within) and within > 0 do
    within |> to_datetime() |> select_all()
  end

  def select_all(%DateTime{} = since) do
    Storage.select_all(Measurement, since)
    |> Stream.map(fn {id, results} -> {Collector.OneWire.label(id), results} end)
    |> Enum.sort()
  end

  defp to_datetime(seconds) when is_integer(seconds) and seconds > 0 do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(-seconds, :second)
  end
end
