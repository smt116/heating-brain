defmodule Collector.RelayState do
  @moduledoc """
  The struct that represents a state of relay.
  """

  @enforce_keys [:id, :value, :timestamp]
  defstruct [:id, :value, :timestamp]

  @type id :: atom
  @type value :: boolean

  @type t ::
          %__MODULE__{
            id: id,
            value: boolean,
            timestamp: DateTime.t()
          }

  @doc """
  Initializes struct for a given state. It assigns current timestamp.
  """
  @spec new(id, value) :: t
  def new(id, value) when is_atom(id) and is_boolean(value) do
    %__MODULE__{
      id: id,
      value: value,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }
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
