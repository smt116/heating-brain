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
  @type relay_state :: RelayState.t()
  @type timestamp :: DateTime.t()
  @type unix_epoch :: pos_integer
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
      |> get_env(:collector, :filesystem_handler).write!(raw_value)

      :ok = RelayState.new(id, value) |> Storage.write()
    end

    :ok
  end

  @doc """
  Reads current values from the file system. It does not interact with the
  database.
  """
  @spec read_all :: list(RelayState.t())
  def read_all do
    get_env(:collector, :relays_map)
    |> Stream.map(fn {id, _pin, _direction} -> {id, relay_value(id)} end)
    |> Enum.map(fn {id, state} -> RelayState.new(id, state) end)
  end

  @doc """
  Returns states for a given relay from the database.
  """
  @spec select(id, timestamp | pos_integer) :: list(relay_state)
  def select(id, within) when is_atom(id) and is_integer(within) and within > 0 do
    select(id, to_datetime(within))
  end

  def select(id, %DateTime{} = since) when is_atom(id) do
    Storage.select(RelayState, id, since)
  end

  @doc """
  Returns states for all, defined relays from the database.
  """
  @spec select(timestamp | pos_integer) :: list({id, list(relay_state)})
  def select(within) when is_integer(within) and within > 0 do
    within |> to_datetime() |> select()
  end

  def select(%DateTime{} = since) do
    Storage.select(RelayState, since)
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
    |> get_env(:collector, :filesystem_handler).read!()
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
    |> get_env(:collector, :filesystem_handler).read!()
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
    handler = get_env(:collector, :filesystem_handler)

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
