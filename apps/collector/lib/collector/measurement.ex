defmodule Collector.Measurement do
  @moduledoc """
  The struct that represents a single sensor's reading.
  """

  import Application, only: [get_env: 2]

  @enforce_keys [:id, :value, :timestamp]
  @derive Jason.Encoder
  defstruct [:id, :value, :expected_value, :timestamp]

  @type id :: atom
  @type timestamp :: DateTime.t()
  @type value :: float

  @type t ::
          %__MODULE__{
            id: id,
            value: value,
            expected_value: value | nil,
            timestamp: timestamp
          }

  @doc """
  Initializes struct for a given reading. It assigns current timestamp if missing.
  """
  @spec new(id, value) :: t
  def new(id, value) do
    at = DateTime.utc_now() |> DateTime.truncate(:second)
    new(id, value, at)
  end

  @doc """
  Initializes struct for a given reading.
  """
  @spec new(id, value, timestamp) :: t
  def new(id, value, %DateTime{} = at) when is_atom(id) and is_float(value) do
    %__MODULE__{
      id: id,
      value: value,
      expected_value: expected_value(id, at),
      timestamp: at
    }
  end

  @spec new(id, value, unix_epoch :: pos_integer) :: t
  def new(id, value, unix_epoch) when is_integer(unix_epoch) and unix_epoch > 0 do
    at = DateTime.from_unix!(unix_epoch)
    new(id, value, at)
  end

  @spec new(id, value, expected_value :: value, timestamp) :: t
  def new(id, value, evalue, %DateTime{} = at)
      when is_atom(id) and is_float(value) and (is_float(evalue) or is_nil(evalue)) do
    %__MODULE__{
      id: id,
      value: value,
      expected_value: evalue,
      timestamp: at
    }
  end

  @spec new(id, value, expected_value :: value, unix_epoch :: pos_integer) :: t
  def new(id, value, evalue, unix_epoch) when is_integer(unix_epoch) and unix_epoch > 0 do
    at = DateTime.from_unix!(unix_epoch)
    new(id, value, evalue, at)
  end

  defp expected_value(id, %DateTime{} = at) do
    case get_env(:collector, :sensors_map) |> Enum.find(&(elem(&1, 1) === id)) do
      nil ->
        nil

      {_, _, _, []} ->
        nil

      {_, _, _, config} ->
        at
        |> DateTime.shift_zone!(get_env(:collector, :timezone))
        |> DateTime.to_time()
        |> Map.fetch!(:hour)
        |> expected_value(config)
    end
  end

  defp expected_value(hour, config) do
    case Enum.find(config, &(hour in elem(&1, 0))) do
      {_, expected_value} -> expected_value
      nil -> nil
    end
  end
end

defimpl String.Chars, for: Collector.Measurement do
  alias Collector.Measurement

  @doc """
  ## Examples

    iex> %Collector.Measurement{
    ...>   id: :"28-0118761f69ff",
    ...>   value: 23.187,
    ...>   expected_value: 24.5,
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z]
    ...> }
    ...> |> to_string()
    "28-0118761f69ff: 23.187°C at 2019-10-28 07:52:26.155383Z (expected: 24.5°C)"

    iex> %Collector.Measurement{
    ...>   id: :pipe,
    ...>   value: 13.5,
    ...>   expected_value: nil,
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z]
    ...> }
    ...> |> to_string()
    "pipe: 13.5°C at 2019-10-28 07:52:26.155383Z"

  """
  @spec to_string(Measurement.t()) :: String.t()
  def to_string(%Measurement{expected_value: nil} = m) do
    "#{m.id}: #{m.value}°C at #{m.timestamp}"
  end

  def to_string(%Measurement{} = m) do
    "#{m.id}: #{m.value}°C at #{m.timestamp} (expected: #{m.expected_value}°C)"
  end
end
