defmodule Collector.OneWireWorker do
  @moduledoc """
  Process for reading values from 1-wire sensors. It queues requests and performs
  one reading at a time to make sure the bus won't be flooded with queries. This is
  important because DS18B20 sensors are using the same wire for power and for data
  transfer. Multiple readings within short period of time will result in errors.
  """

  use GenServer

  alias Collector.OneWire

  @opaque state :: []
  @typep from :: GenServer.from()
  @type id :: Collector.Measurement.raw_id()

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec start_link(list) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @spec handle_call({:read, id}, from, state) :: {:reply, OneWire.read(), state}
  def handle_call({:read, id}, _pid, state), do: {:reply, OneWire.read(id), state}

  @doc """
  Read values from all available sensors.

  ## Examples

      iex> Collector.OneWireWorker.read_all()
      [
        ok: %Collector.Measurement{
          id: :"28-01187615e4ff",
          timestamp: ~U[2020-01-11 14:03:51Z],
          value: 21.125
        },
        ok: %Collector.Measurement{
          id: :"28-0118761f69ff",
          timestamp: ~U[2020-01-11 14:03:51Z],
          value: -8.5
        },
        ok: %Collector.Measurement{
          id: :"28-01187654b6ff",
          timestamp: ~U[2020-01-11 14:03:51Z],
          value: 24.0
        }
      ]

  """
  @spec read_all :: list(OneWire.read())
  def read_all do
    OneWire.sensors()
    |> Stream.map(&read/1)
    |> Enum.sort_by(&by/1)
  end

  @spec read(String.t()) :: OneWire.read()
  defp read(id), do: GenServer.call(__MODULE__, {:read, id})

  defp by({:ok, %{id: id}}), do: {0, id}
  defp by(result), do: {1, result}
end
