defmodule Collector.Measurement do
  @moduledoc """
  The struct that represents a single sensor's reading.
  """

  @enforce_keys [:id, :value, :timestamp]
  defstruct [:id, :value, :expected_value, :timestamp]

  @type id :: atom
  @type timestamp :: DateTime.t()
  @type value :: float

  @type t ::
          %__MODULE__{
            id: id,
            value: value,
            expected_value: value,
            timestamp: timestamp
          }

  @doc """
  Initializes struct for a given reading. It assigns current timestamp if missing.
  """
  @spec new(id, value) :: t
  def new(id, val) do
    at = DateTime.utc_now() |> DateTime.truncate(:second)
    eval = expected_value(id)
    new(id, val, eval, at)
  end

  @doc """
  Initializes struct for a given reading.
  """
  @spec new(id, value :: value, expected_value :: value | nil, timestamp) :: t
  def new(id, val, eval, %DateTime{} = at)
      when is_atom(id) and is_float(val) and (is_nil(eval) or is_float(eval)) do
    %__MODULE__{
      id: id,
      value: val,
      expected_value: eval,
      timestamp: at
    }
  end

  @spec new(id, value :: value, expected_value :: value | nil, unix_epoch :: pos_integer) :: t
  def new(id, val, eval, unix_epoch) when is_integer(unix_epoch) and unix_epoch > 0 do
    at = DateTime.from_unix!(unix_epoch)
    new(id, val, eval, at)
  end

  @spec expected_value(id) :: value
  defp expected_value(id) when is_atom(id) do
    Application.get_env(:collector, :sensors_map)
    |> Enum.map(fn {_, label, _, eval} -> {label, eval} end)
    |> Keyword.get(id, nil)
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
