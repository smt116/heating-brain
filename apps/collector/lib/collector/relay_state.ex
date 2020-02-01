defmodule Collector.RelayState do
  @moduledoc """
  The struct that represents a state of relay.
  """

  @enforce_keys [:id, :value, :timestamp]
  defstruct [:id, :value, :timestamp]

  @type id :: atom
  @type timestamp :: DateTime.t()
  @type value :: boolean

  @type t ::
          %__MODULE__{
            id: id,
            value: boolean,
            timestamp: timestamp
          }

  @doc """
  Initializes struct for a given state. It assigns current timestamp if missing.
  """
  def new(id, val) do
    timestamp = DateTime.utc_now() |> DateTime.truncate(:second)
    new(id, val, timestamp)
  end

  @doc """
  Initializes struct for a given state.
  """
  @spec new(id, value, timestamp) :: t
  def new(id, val, %DateTime{} = timestamp) when is_atom(id) and is_boolean(val) do
    %__MODULE__{
      id: id,
      value: val,
      timestamp: timestamp
    }
  end

  @spec new(id, value, unix_epoch :: pos_integer) :: t
  def new(id, val, unix_epoch) when is_integer(unix_epoch) and unix_epoch > 0 do
    at = DateTime.from_unix!(unix_epoch)
    new(id, val, at)
  end
end

defimpl String.Chars, for: Collector.RelayState do
  alias Collector.RelayState

  @doc """
  ## Examples

    iex> %Collector.RelayState{
    ...>   id: :valve,
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z],
    ...>   value: true
    ...> }
    ...> |> to_string()
    "valve: true at 2019-10-28 07:52:26.155383Z"

  """
  @spec to_string(RelayState.t()) :: String.t()
  def to_string(%RelayState{id: id, value: value, timestamp: timestamp}) do
    "#{id}: #{value} at #{timestamp}"
  end
end
