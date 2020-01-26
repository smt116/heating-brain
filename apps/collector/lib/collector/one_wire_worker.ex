defmodule Collector.OneWireWorker do
  @moduledoc """
  Process for reading values from 1-wire sensors. It queues requests and performs
  one reading at a time to make sure the bus won't be flooded with queries. This is
  important because DS18B20 sensors are using the same wire for power and for data
  transfer. Multiple readings within short period of time will result in errors.
  """

  use GenServer

  alias Collector.OneWire

  @opaque state :: [last_read_at: pos_integer]
  @typep from :: GenServer.from()
  @type id :: Collector.Measurement.raw_id()

  @delay_between_readings Application.get_env(:collector, :w1_bus_delay_between_readings)

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec start_link([]) :: GenServer.on_start()
  def start_link([]) do
    GenServer.start_link(__MODULE__, [last_read_at: 0], name: __MODULE__)
  end

  defp now_in_millisecond, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  @impl true
  @spec handle_call({:read, id}, from, state) :: {:reply, OneWire.read(), state}
  def handle_call({:read, id}, _pid, last_read_at: last_read_at) do
    delay = last_read_at + @delay_between_readings - now_in_millisecond()

    if delay > 0 do
      :timer.sleep(delay)
    end

    {:reply, OneWire.read(id), [last_read_at: now_in_millisecond()]}
  end

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

  @doc """
  Read value from a given sensor.

  ## Examples

      iex> Collector.OneWireWorker.read("28-01187615e4ff")
      [
        ok: %Collector.Measurement{
          id: :"28-01187615e4ff",
          timestamp: ~U[2020-01-11 14:03:51Z],
          value: 21.125
        }
      ]

  """
  @spec read(String.t()) :: OneWire.read()
  def read(id), do: GenServer.call(__MODULE__, {:read, id})

  defp by({:ok, %{id: id}}), do: {0, id}
  defp by(result), do: {1, result}
end
