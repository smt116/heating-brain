defmodule Collector.Relays do
  @moduledoc """
  The interface for relays. It allows checking current values (via the filesystem)
  and reading historical data from the storage.
  """

  require Logger

  alias Collector.RelayState
  alias Collector.Storage

  @gpio_base_path Application.get_env(:collector, :gpio_base_path)
  @handler Application.get_env(:collector, :filesystem_handler)
  @relays_map Application.get_env(:collector, :relays_map)

  @type label :: RelayState.label()
  @type timestamp :: DateTime.t()
  @type value :: RelayState.value()

  @doc """
  Reads latest, known values from the database with the timestamp of last check.

  ## Examples

      iex> Collector.Relays.current()
      [
        heating: {~U[2019-12-01 09:52:14Z], true},
        valve1: {~U[2019-12-01 09:52:14Z], true},
        valve2: {~U[2019-12-01 09:52:14Z], true},
        valve3: {~U[2019-12-01 09:52:14Z], false},
      ]

  """
  @spec current :: [{label, value, {timestamp, timestamp}}]
  def current do
    # In fact, it should be :mnesia.last with ordered_set table but this kind of
    # semantic is not supported for disc_only_copies.
    #
    # FIXME: use disc_copies semantic
    #        http://erlang.org/doc/man/mnesia.html#description
    fn %{label: label, value: value, timestamp: timestamp}, acc ->
      acc
      |> Keyword.put_new(label, nil)
      |> Keyword.get_and_update(label, &{&1, newer(&1, {timestamp, value})})
      |> elem(1)
      |> Enum.reject(fn {_label, value} -> is_nil(value) end)
    end
    |> Storage.read(RelayState)
    |> Enum.sort()
  end

  @doc """
  Change the state of relay according to the given struct.
  """
  @spec put_state(RelayState.t()) :: :ok
  def put_state(%RelayState{label: label, value: value}) do
    if relay_value(label) == value do
      Logger.debug(fn -> "#{label} has already #{value} state" end)
    else
      raw_value = boolean_to_raw_value(value)

      label
      |> relay_raw_value_path()
      |> @handler.write!(raw_value)

      :ok = RelayState.new(label, value) |> Storage.write()
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
          label: :heating,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: true
        },
        %Collector.RelayState{
          label: :valve1,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: false
        },
        %Collector.RelayState{
          label: :valve2,
          timestamp: ~U[2019-12-01 09:59:37Z],
          value: true
        }
      ]

  """
  @spec read_all :: list(RelayState.t())
  def read_all do
    @relays_map
    |> Stream.map(fn {label, _pin, _direction} -> {label, relay_value(label)} end)
    |> Enum.map(fn {label, state} -> RelayState.new(label, state) end)
  end

  @spec setup_all :: :ok
  def setup_all, do: Enum.each(@relays_map, &setup/1)

  defp boolean_to_raw_value(true), do: "1"
  defp boolean_to_raw_value(false), do: "0"

  @spec newer({timestamp, value}, {timestamp, value}) :: {timestamp, value}
  defp newer(nil, candidate), do: candidate
  defp newer({a, _} = current, {b, _}) when a >= b, do: current
  defp newer(_current, candidate), do: candidate

  defp raw_value_to_boolean("0"), do: false
  defp raw_value_to_boolean("1"), do: true

  defp relay_direction(label) do
    label
    |> relay_direction_path()
    |> @handler.read!()
    |> String.trim()
  end

  defp relay_direction_path(label) do
    label
    |> relay_directory_path()
    |> Path.join("direction")
  end

  defp relay_directory_path(label) do
    {_label, pin, _direction} = Enum.find(@relays_map, &(elem(&1, 0) === label))

    Path.join([@gpio_base_path, to_string(pin)])
  end

  defp relay_raw_value(label) do
    label
    |> relay_raw_value_path()
    |> @handler.read!()
    |> String.trim()
  end

  defp relay_raw_value_path(label) do
    label
    |> relay_directory_path()
    |> Path.join("value")
  end

  defp relay_value(label) do
    label
    |> relay_raw_value()
    |> raw_value_to_boolean()
  end

  defp setup({label, pin, direction}) do
    if relay_directory_path(label) |> @handler.dir?() do
      Logger.debug(fn -> "Pin #{pin} for #{label} is already exported" end)
    else
      Logger.info(fn -> "Exporing pin #{pin} for #{label}" end)
      Path.join(@gpio_base_path, "export") |> @handler.write!(to_string(pin))
    end

    if relay_direction(label) === direction do
      Logger.debug(fn -> "Pin #{pin} for #{label} is already as #{direction}" end)
    else
      Logger.info(fn -> "Setting up pin #{pin} as #{direction} for #{label}" end)
      label |> relay_direction() |> @handler.write!(direction)
    end

    :ok
  end
end
