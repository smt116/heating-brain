defmodule Collector.RelayState do
  @moduledoc """
  The struct that represents a state of relay.
  """

  @enforce_keys [:label, :value, :timestamp]
  defstruct [:label, :value, :timestamp]

  @type label :: atom
  @type value :: boolean

  @type t ::
  %__MODULE__{
    label: label,
    value: boolean,
    timestamp: DateTime.t()
  }

  @doc """
  Initializes struct for a given state. It assigns current timestamp.
  """
  @spec new(label, value) :: t
  def new(label, value) when is_atom(label) and is_boolean(value) do
    %__MODULE__{
      label: label,
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
    ...>   label: :valve,
    ...>   timestamp: ~U[2019-10-28 07:52:26.155383Z],
    ...>   value: true
    ...> }
    ...> |> to_string()
    "valve: true at 2019-10-28 07:52:26.155383Z"

  """
  @spec to_string(RelayState.t()) :: String.t()
  def to_string(%RelayState{label: label, value: value, timestamp: timestamp}) do
    "#{label}: #{value} at #{timestamp}"
  end
end
