defmodule Collector.Measurement do
  @moduledoc """
  The struct that represents a single sensor's reading.
  """

  @enforce_keys [:id, :value, :timestamp]
  defstruct [:id, :value, :timestamp]

  @opaque id :: atom
  @type raw_id :: String.t()
  @type value :: float

  @type t ::
          %__MODULE__{
            id: id,
            value: float,
            timestamp: DateTime.t()
          }

  @doc """
  Initializes struct for a given reading. It assigns current timestamp.
  """
  @spec new(raw_id, value) :: t
  def new(id, value) when is_binary(id) and is_float(value) do
    %__MODULE__{
      id: String.to_atom(id),
      value: value,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end
end

defimpl String.Chars, for: Collector.Measurement do
  alias Collector.Measurement

  @doc """
  ## Examples

    iex> %Collector.Measurement{
    ...>   id: :"28-0118761f69ff",
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z],
    ...>   value: 23.187
    ...> }
    ...> |> to_string()
    "28-0118761f69ff: 23.187°C at 2019-10-28 07:52:26.155383Z"

  """
  @spec to_string(Measurement.t()) :: String.t()
  def to_string(%Measurement{id: id, value: value, timestamp: timestamp}) do
    "#{id}: #{value}°C at #{timestamp}"
  end
end
