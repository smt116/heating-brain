defmodule Collector.Relays do
  @moduledoc """
  The interface for relays. It allows reading all current values via the filesystem
  and also accessing historical data from the storage.
  """

  require Logger

  import Application, only: [get_env: 2]

  alias Collector.RelayState
  alias Collector.Storage

  @type id :: RelayState.id()
  @type simplified_states :: list({timestamp, value})
  @type timestamp :: DateTime.t()
  @type value :: RelayState.value()

  @doc """
  Change the state of relay according to the given struct.
  """
  @spec put_state(RelayState.t()) :: :ok
  def put_state(%RelayState{id: id, value: value}) do
    if relay_value(id) == value do
      Logger.debug(fn -> "#{id} has already #{value} state" end)
    else
      raw_value = boolean_to_raw_value(value)

      id
      |> relay_raw_value_path()
      |> Application.get_env(:collector, :filesystem_handler).write!(raw_value)

      :ok = RelayState.new(id, value) |> Storage.write()
    end

    :ok
  end

  @doc """
  Reads current values from the file system. It does not interact with the
  database.

  ## Examples

      iex> Collector.Relays.read_all()
      [
        %Collector.RelayState{
          id: :heating,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: true
        },
        %Collector.RelayState{
          id: :valve1,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: false
        },
        %Collector.RelayState{
          id: :valve2,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: true
        }
      ]
  """
  @spec read_all :: list(RelayState.t())
  def read_all do
    get_env(:collector, :relays_map)
    |> Stream.map(fn {id, _pin, _direction} -> {id, relay_value(id)} end)
    |> Enum.map(fn {id, state} -> RelayState.new(id, state) end)
  end

  @doc """
  Returns states for a given relay. The results are limitated to those that were
  read within last N seconds (default: 5 minutes).

  ## Examples

      iex> Collector.Relays.select(:valve6, 60)
      [
        {~U[2020-01-26 09:18:49Z], false}
      ]

      iex> Collector.Relays.select(:valve6)
      [
        {~U[2020-01-26 09:17:40Z], true},
        {~U[2020-01-26 09:18:49Z], false}
      ]

  """
  @spec select(id, timestamp | pos_integer) :: simplified_states
  def select(id, within \\ 300)

  def select(id, within) when is_atom(id) and is_integer(within) and within > 0 do
    select(id, to_datetime(within))
  end

  def select(id, %DateTime{} = since) when is_atom(id) do
    Storage.select(RelayState, id, since)
  end

  @doc """
  Returns states for all, defined relays. The results are limitated to those
  that were read within last N seconds (default: 5 minutes).

  ## Examples

      iex> Collector.Relays.select_all(60)
      [
        heating: [
          {~U[2020-01-26 09:21:44Z], true},
          {~U[2020-01-26 09:22:37Z], false}
        ],
        pump: [{~U[2020-01-26 09:22:37Z], false}],
        valve1: [
          {~U[2020-01-26 09:22:37Z], false},
          {~U[2020-01-26 09:22:40Z], true}
        ]
      ]

      iex> Collector.Relays.select_all()
      [
        heating: [
          {~U[2020-01-26 09:17:48Z], true},
          {~U[2020-01-26 09:18:49Z], false},
          {~U[2020-01-26 09:21:36Z], false},
          {~U[2020-01-26 09:22:45Z], true}
        ],
        pump: [
          {~U[2020-01-26 09:17:40Z], false},
          {~U[2020-01-26 09:18:49Z], false},
          {~U[2020-01-26 09:21:36Z], false},
          {~U[2020-01-26 09:22:37Z], false}
        ],
        valve1: [
          {~U[2020-01-26 09:17:40Z], false},
          {~U[2020-01-26 09:18:49Z], false},
          {~U[2020-01-26 09:21:39Z], true},
          {~U[2020-01-26 09:22:40Z], true}
        ]
      ]

  """
  @spec select_all(timestamp | pos_integer) :: list({id, simplified_states})
  def select_all(within \\ 300)

  def select_all(within) when is_integer(within) and within > 0 do
    within |> to_datetime() |> select_all()
  end

  def select_all(%DateTime{} = since) do
    Storage.select_all(RelayState, since)
  end

  @spec setup_all :: :ok
  def setup_all, do: get_env(:collector, :relays_map) |> Enum.each(&setup/1)

  defp boolean_to_raw_value(true), do: "1"
  defp boolean_to_raw_value(false), do: "0"

  defp raw_value_to_boolean("0"), do: false
  defp raw_value_to_boolean("1"), do: true

  defp relay_direction(id) do
    id
    |> relay_direction_path()
    |> Application.get_env(:collector, :filesystem_handler).read!()
    |> String.trim()
  end

  defp relay_direction_path(id) do
    id
    |> relay_directory_path()
    |> Path.join("direction")
  end

  defp relay_directory_path(id) do
    {_id, pin, _direction} = get_env(:collector, :relays_map) |> Enum.find(&(elem(&1, 0) === id))

    Path.join([get_env(:collector, :gpio_base_path), "gpio#{to_string(pin)}"])
  end

  defp relay_raw_value(id) do
    id
    |> relay_raw_value_path()
    |> Application.get_env(:collector, :filesystem_handler).read!()
    |> String.trim()
  end

  defp relay_raw_value_path(id) do
    id
    |> relay_directory_path()
    |> Path.join("value")
  end

  defp relay_value(id) do
    id
    |> relay_raw_value()
    |> raw_value_to_boolean()
  end

  defp setup({id, pin, direction}) do
    handler = Application.get_env(:collector, :filesystem_handler)

    if relay_directory_path(id) |> handler.dir?() do
      Logger.debug(fn -> "Pin #{pin} for #{id} is already exported" end)
    else
      Logger.info(fn -> "Exporing pin #{pin} for #{id}" end)

      :ok =
        get_env(:collector, :gpio_base_path)
        |> Path.join("export")
        |> handler.write!(to_string(pin))
    end

    if relay_direction(id) === direction do
      Logger.debug(fn -> "Pin #{pin} for #{id} is already as #{direction}" end)
    else
      Logger.info(fn -> "Setting up pin #{pin} as #{direction} for #{id}" end)
      :ok = id |> relay_direction_path() |> handler.write!(direction)
    end

    :ok
  end

  defp to_datetime(seconds) when is_integer(seconds) and seconds > 0 do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(-seconds, :second)
  end
end
