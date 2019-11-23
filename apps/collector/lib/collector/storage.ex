defmodule Collector.Storage do
  @moduledoc """
  The interface for interacting with database. It uses Mnesia under-the-hood.
  """

  require Logger

  alias :mnesia, as: Mnesia
  alias Collector.Measurement

  @type measurement :: Measurement.t()

  @opaque state :: []

  @spec init() :: :ok
  def init do
    Logger.debug(fn -> "Initializing Mnesia database" end)
    Mnesia.create_schema([node()])

    :ok = Mnesia.start()
    :ok = initialize_table(Measurement, [:reading, :unix])
    :ok = Mnesia.wait_for_tables([Measurement], 5000)

    :ok
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

  defp to_struct({Measurement, {id, unix}, value}) do
    {:ok, timestamp} = DateTime.from_unix(unix)
    %Measurement{id: id, value: value, timestamp: timestamp}
  end
end
