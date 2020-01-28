defmodule Collector.Measurement do
  @moduledoc """
  The struct that represents a single sensor's reading.
  """

  @enforce_keys [:id, :label, :value, :timestamp]
  defstruct [:id, :label, :value, :timestamp]

  @type id :: atom
  @type label :: atom
  @type timestamp :: DateTime.t()
  @type value :: float

  @type t ::
          %__MODULE__{
            id: id,
            label: label,
            value: float,
            timestamp: timestamp
          }

  @doc """
  Initializes struct for a given reading. It assigns current timestamp if missing.
  """
  @spec new(id, value, timestamp | nil) :: t
  def new(id, val, %DateTime{} = at) when is_atom(id) and is_float(val) do
    %__MODULE__{
      id: id,
      label: Collector.OneWire.label(id),
      value: val,
      timestamp: at
    }
  end

  def new(id, val) when is_atom(id) and is_float(val) do
    at = DateTime.utc_now() |> DateTime.truncate(:second)
    new(id, val, at)
  end
end

defimpl String.Chars, for: Collector.Measurement do
  alias Collector.Measurement

  @doc """
  ## Examples

    iex> %Collector.Measurement{
    ...>   id: :"28-0118761f69ff",
    ...>   label: :pipe,
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z],
    ...>   value: 23.187
    ...> }
    ...> |> to_string()
    "28-0118761f69ff (pipe): 23.187°C at 2019-10-28 07:52:26.155383Z"

  """
  @spec to_string(Measurement.t()) :: String.t()
  def to_string(%Measurement{} = m) do
    "#{m.id} (#{m.label}): #{m.value}°C at #{m.timestamp}"
  end
end
