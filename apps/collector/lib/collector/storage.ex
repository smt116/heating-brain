defmodule Collector.Storage do
  @moduledoc """
  The interface for interacting with database. It uses Mnesia under-the-hood.
  """

  use GenServer

  require Logger

  alias :mnesia, as: Mnesia
  alias Collector.Measurement

  @type measurement :: Measurement.t()

  @typep caller :: {pid, term}
  @typep unix_timestamp :: pos_integer

  @typep db_m_key :: {Measurement.id(), unix_timestamp}
  @typep db_m :: {Measurement, db_m_key, float}
  @typep db_m_write :: {:write, db_m, term}
  @typep db_m_delete_object :: {:delete_object, db_m, term}
  @typep db_m_delete :: {:delete, {Measurement, db_m_key}, term}

  @typep mnesia_table_event ::
    {:mnesia_table_event, db_m_write
                        | db_m_delete_object
                        | db_m_delete}

  @opaque state :: list({pid, reference})

  @impl true
  @spec init(state) :: {:ok, state}
  def init(subscribers) do
    Logger.debug(fn -> "Initializing Mnesia database" end)
    Mnesia.create_schema([node()])

    :ok = Mnesia.start()
    :ok = initialize_table(Measurement, [:reading, :unix])
    :ok = Mnesia.wait_for_tables([Measurement], 5000)

    Logger.debug(fn -> "Subscribing to Measurement table events" end)
    Mnesia.subscribe({:table, Measurement, :simple})

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
  @spec handle_cast({:publish, measurement}, state) :: {:noreply, state}
  def handle_cast({:publish, measurement}, subscribers) do
    Logger.debug(fn ->
      receivers = Enum.map(subscribers, fn {pid, _} -> label(pid) end)
      "Publishing #{measurement} to #{inspect(receivers)}"
    end)

    Enum.each(subscribers, fn {pid, _} ->
      Process.send(pid, {:new_record, measurement}, [])
    end)

    {:noreply, subscribers}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, subscribers) do
    Logger.warn(fn -> "Subscribed #{label(pid)} is down" end)
    GenServer.call(__MODULE__, {:unsubscribe, pid})
    {:noreply, subscribers}
  end

  @impl true
  @spec handle_info(mnesia_table_event, state) :: {:noreply, state}
  def handle_info({:mnesia_table_event, event}, subscribers) do
    case event do
      {:write, {Measurement, _, _} = measurement, _} ->
        measurement |> to_struct() |> publish()

      {type, record, _} ->
        Logger.debug(fn -> "Unhandled Mnesia #{type}: #{inspect(record)}" end)
    end

    {:noreply, subscribers}
  end

  @spec start_link(state) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Reads measurements from the database. It requires a function that will be used to
  fold data.

  ## Examples

      iex> fn %{id: id, value: value, timestamp: timestamp}, acc ->
      ...>   acc
      ...>   |> Keyword.put_new(id, [])
      ...>   |> Keyword.get_and_update(id, & {&1, [{timestamp, value} | &1]})
      ...>   |> elem(1)
      ...> end
      ...> |> Collector.Storage.read(Measurement)
      [
        "28-0118761f69ff": [
          {~U[2019-10-28 07:46:56Z], 21.875},
          {~U[2019-10-28 07:47:13Z], 21.875}
        ],
        "28-01187615e4ff": [
          {~U[2019-10-28 07:46:55Z], 23.687},
          {~U[2019-10-28 07:47:12Z], 23.437}
        ]
      ]

  """
  @spec read((measurement, list(r) -> list(r)), Measurement) :: list(r) when r: any
  def read(f, table_name) do
    fn -> Mnesia.foldl(& to_struct(&1) |> f.(&2), [], table_name) end
    |> Mnesia.transaction()
    |> handle_result()
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
  Writes a given measurement to the database.
  """
  @spec write(measurement) :: :ok | {:error, tuple}
  def write(%{} = struct) do
    fn ->
      struct
      |> from_struct()
      |> Mnesia.write()
    end
    |> Mnesia.transaction()
    |> handle_result(struct)
  end

  defp from_struct(%Measurement{id: id, value: value, timestamp: timestamp}) do
    {Measurement, {id, DateTime.to_unix(timestamp)}, value}
  end

  defp handle_result({:atomic, result}), do: result
  defp handle_result({:aborted, reason}) do
    Logger.error(fn -> "Reading failed: #{inspect(reason)}" end)

    {:error, reason}
  end

  defp handle_result({:atomic, :ok}, _struct), do: :ok
  defp handle_result({:aborted, reason}, struct) do
    Logger.error(fn -> "Writing #{struct} failed: #{reason}" end)

    {:error, reason}
  end

  defp initialize_table(table_name, attributes) do
    opts = [
      attributes: attributes,
      disc_only_copies: [node()]
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

  defp to_struct({Measurement, {id, unix}, value}) do
    {:ok, timestamp} = DateTime.from_unix(unix)
    %Measurement{id: id, value: value, timestamp: timestamp}
  end
end
