defmodule Collector.Storage do
  @moduledoc """
  The internal interface for interacting with database. It shouldn't be used
  directly except subscribing to the database events. The storage uses Mnesia
  under-the-hood.
  """

  use GenServer

  require Logger

  import DateTime, only: [to_unix: 1]

  alias :mnesia, as: Mnesia
  alias Collector.Measurement
  alias Collector.RelayState

  @type measurement :: Measurement.t()
  @type relay_state :: RelayState.t()

  @type record :: measurement | relay_state
  @type table :: Measurement | RelayState
  @type timestamp :: DateTime.t()

  @typep caller :: {pid, term}
  @typep unix_timestamp :: pos_integer

  @typep db_m_key :: {Measurement.id(), unix_timestamp}
  @typep db_m :: {Measurement, db_m_key, float}
  @typep db_m_write :: {:write, db_m, term}
  @typep db_m_delete_object :: {:delete_object, db_m, term}
  @typep db_m_delete :: {:delete, {Measurement, db_m_key}, term}

  @typep db_r_key :: {RelayState.id(), unix_timestamp}
  @typep db_r :: {RelayState, db_r_key, boolean}
  @typep db_r_write :: {:write, db_r, term}
  @typep db_r_delete_object :: {:delete_object, db_r, term}
  @typep db_r_delete :: {:delete, {RelayState, db_r_key}, term}

  @typep mnesia_table_event ::
           {:mnesia_table_event,
            db_m_write
            | db_m_delete_object
            | db_m_delete
            | db_r_write
            | db_r_delete_object
            | db_r_delete}

  @opaque state :: list({pid, reference})

  @impl true
  @spec init(state) :: {:ok, state}
  def init(subscribers) do
    Logger.info(fn -> "Initializing Mnesia database" end)
    :ok = File.mkdir_p("mnesia")

    Mnesia.create_schema([node()])

    :ok = Mnesia.start()
    :ok = initialize_table(Measurement, [:point, :value, :expected_value])
    :ok = initialize_table(RelayState, [:point, :state])
    :ok = Mnesia.wait_for_tables([Measurement, RelayState], 60_000)

    Enum.each([Measurement, RelayState], fn table ->
      Logger.info(fn -> "Subscribing to #{table} table events" end)
      Mnesia.subscribe({:table, table, :simple})
    end)

    {:ok, subscribers}
  end

  @impl true
  @spec handle_call(:subscribe, caller, state) :: {:reply, :ok | :error, state}
  def handle_call(:subscribe, {pid, _tag}, subscribers) do
    cond do
      Enum.any?(subscribers, fn {p, _} -> p === pid end) ->
        Logger.debug(fn -> "#{label(pid)} is already subscribed" end)
        {:reply, :ok, subscribers}

      Process.alive?(pid) ->
        Logger.debug(fn -> "Subscribing #{label(pid)} to Storage events" end)
        ref = Process.monitor(pid)
        {:reply, :ok, [{pid, ref} | subscribers]}

      true ->
        Logger.warn(fn -> "#{label(pid)} is down" end)
        {:reply, :error, subscribers}
    end
  end

  @impl true
  @spec handle_call({:unsubscribe, pid}, caller, state) :: {:reply, :ok, state}
  def handle_call({:unsubscribe, pid}, {_caller, _tag}, subscribers) do
    Logger.debug(fn -> "Unsubscribing #{label(pid)} from Storage events" end)

    case Enum.find(subscribers, fn {p, _} -> p === pid end) do
      {_, ref} ->
        Process.demonitor(ref)
        {:reply, :ok, List.delete(subscribers, {pid, ref})}

      _ ->
        {:reply, :ok, subscribers}
    end
  end

  @impl true
  @spec handle_cast({:publish, record}, state) :: {:noreply, state}
  def handle_cast({:publish, record}, subscribers) do
    Logger.debug(fn ->
      receivers = Enum.map(subscribers, fn {pid, _} -> label(pid) end)
      "Publishing #{record} to #{inspect(receivers)}"
    end)

    Enum.each(subscribers, fn {pid, _} ->
      Process.send(pid, {:new_record, record}, [])
    end)

    {:noreply, subscribers}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, subscribers) do
    Logger.debug(fn -> "Subscribed #{label(pid)} is down" end)
    tuple = Enum.find(subscribers, fn {pid, _} -> pid === pid end)
    {:noreply, List.delete(subscribers, tuple)}
  end

  @impl true
  @spec handle_info(mnesia_table_event, state) :: {:noreply, state}
  def handle_info({:mnesia_table_event, event}, subscribers) do
    case event do
      {:write, {Measurement, _, _, _} = measurement, _} ->
        measurement |> to_struct() |> publish()

      {:write, {RelayState, _, _} = relay_state, _} ->
        relay_state |> to_struct() |> publish()

      {:delete, record, _} ->
        Logger.debug(fn -> "Record has been deleted: #{inspect(record)}" end)

      {type, record, _} ->
        Logger.warn(fn -> "Unhandled Mnesia #{type}: #{inspect(record)}" end)
    end

    {:noreply, subscribers}
  end

  @spec create_backup :: :ok
  def create_backup do
    backups_directory = Application.get_env(:mnesia, :backups_directory)

    timestamp =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601(:basic)

    filename = Enum.join(["mnesia", node() |> to_string(), timestamp], ".")
    path = Path.join([backups_directory, filename])

    :ok = path |> to_charlist() |> :mnesia.backup()
  end

  @spec start_link(state) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec select(atom, tuple) :: list({atom, list(term)})
  def select(table, query) when is_atom(table) and is_tuple(query) do
    fn -> Mnesia.select(table, [query]) end
    |> Mnesia.transaction()
    |> handle_select(table)
  end

  @spec select(Measurement, timestamp) :: list({Measurement.id(), list(measurement)})
  def select(Measurement, %DateTime{} = dt) do
    select(Measurement, {
      {Measurement, {:"$1", :"$2"}, :"$3", :"$4"},
      [
        {:>, :"$2", to_unix(dt)}
      ],
      [
        [:"$1", :"$3", :"$4", :"$2"]
      ]
    })
  end

  @spec select(RelayState, timestamp) :: list({RelayState.id(), list(relay_state)})
  def select(RelayState, %DateTime{} = dt) do
    select(RelayState, {
      {RelayState, {:"$1", :"$2"}, :"$3"},
      [
        {:>, :"$2", to_unix(dt)}
      ],
      [
        [:"$1", :"$3", :"$2"]
      ]
    })
  end

  @spec select(table, tuple, atom) :: list(term)
  def select(t, query, id) when is_atom(t) and is_atom(id) and is_tuple(query) do
    fn -> Mnesia.select(t, [query]) end
    |> Mnesia.transaction()
    |> handle_select(t, id)
  end

  @spec select(Measurement, Measurement.id(), timestamp) :: list(measurement)
  def select(Measurement, id, %DateTime{} = dt) when is_atom(id) do
    select(
      Measurement,
      {
        {Measurement, {:"$1", :"$2"}, :"$3", :"$4"},
        [
          {:==, :"$1", id},
          {:>, :"$2", to_unix(dt)}
        ],
        [
          [:"$1", :"$3", :"$4", :"$2"]
        ]
      },
      id
    )
  end

  @spec select(RelayState, RelayState.id(), timestamp) :: list(relay_state)
  def select(RelayState, id, %DateTime{} = dt) when is_atom(id) do
    select(
      RelayState,
      {
        {RelayState, {:"$1", :"$2"}, :"$3"},
        [
          {:==, :"$1", id},
          {:>, :"$2", to_unix(dt)}
        ],
        [
          [:"$1", :"$3", :"$2"]
        ]
      },
      id
    )
  end

  @doc """
  Subscribes to events emited by the storage, i. e. table events such as new
  measurement saved into the database.
  """
  @spec subscribe :: :ok
  def subscribe do
    GenServer.call(__MODULE__, :subscribe)
  end

  @doc """
  Unsubscribes from events emited by the storage.
  """
  @spec unsubscribe(pid) :: :ok
  def unsubscribe(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:unsubscribe, pid})
  end

  @doc """
  Writes a given record to the database.
  """
  @spec write(record) :: :ok | {:error, tuple}
  def write(%{} = struct) do
    fn ->
      struct
      |> from_struct()
      |> Mnesia.write()
    end
    |> Mnesia.transaction()
    |> handle_write_result(struct)
  end

  defp from_struct(%Measurement{} = r) do
    {Measurement, {r.id, to_unix(r.timestamp)}, r.value, r.expected_value}
  end

  defp from_struct(%RelayState{} = r) do
    {RelayState, {r.id, to_unix(r.timestamp)}, r.value}
  end

  defp handle_select({:atomic, r}, table) when is_list(r) do
    r
    |> Stream.map(&apply(table, :new, &1))
    |> Enum.group_by(& &1.id)
    |> Stream.map(fn {id, list} -> {id, Enum.sort_by(list, & &1.timestamp)} end)
    |> Enum.sort()
  end

  defp handle_select({:aborted, reason}, table) do
    Logger.error(fn ->
      "Selecting from #{table} failed: #{inspect(reason)}"
    end)

    {:error, reason}
  end

  defp handle_select({:atomic, r}, table, id) when is_list(r) do
    handle_select({:atomic, r}, table) |> Keyword.get(id, [])
  end

  defp handle_select({:aborted, reason}, table, id) do
    Logger.error(fn ->
      "Selecting from #{table} failed for #{id}: #{inspect(reason)}"
    end)

    {:error, reason}
  end

  defp handle_write_result({:atomic, :ok}, _struct), do: :ok

  defp handle_write_result({:aborted, reason}, struct) do
    Logger.error(fn -> "Writing #{inspect(struct)} failed: #{reason}" end)

    {:error, reason}
  end

  defp initialize_table(table_name, attributes) do
    tables_storage = Application.get_env(:mnesia, :tables_storage)

    opts = [
      {:attributes, attributes},
      {tables_storage, [node()]}
    ]

    case Mnesia.create_table(table_name, opts) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, _}} -> :ok
      result -> result
    end
  end

  defp label(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      pid
      |> Process.info()
      |> Keyword.get(:registered_name, pid)
      |> inspect()
    else
      inspect(pid)
    end
  end

  defp label(value), do: inspect(value)

  defp publish(record), do: GenServer.cast(__MODULE__, {:publish, record})

  defp to_struct({Measurement, {id, unix_epoch}, val, eval}) do
    Measurement.new(id, val, eval, unix_epoch)
  end

  defp to_struct({RelayState, {id, unix_epoch}, value}) do
    RelayState.new(id, value, unix_epoch)
  end
end
