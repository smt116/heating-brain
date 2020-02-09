defmodule Collector.OneWireWorker do
  @moduledoc """
  Process for reading values from 1-wire sensors. It queues requests and performs
  one reading at a time to make sure the bus won't be flooded with queries. This is
  important because DS18B20 sensors are using the same wire for power and for data
  transfer. Multiple readings within short period of time will result in errors.
  """

  use GenServer

  import Application, only: [compile_env: 2, get_env: 2]

  alias Collector.Measurement
  alias Collector.OneWire

  @opaque state :: [last_read_at: pos_integer]
  @type id :: Measurement.id()
  @typep from :: GenServer.from()

  @delay_between_readings_on_timeout 10_000
  @read_timeout compile_env(:collector, :w1_bus_read_timeout)

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec start_link([]) :: GenServer.on_start()
  def start_link([]) do
    GenServer.start_link(__MODULE__, [last_read_at: 0], name: __MODULE__)
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  @impl true
  @spec handle_call({:read, id}, from, state) :: {:reply, OneWire.read(), state}
  def handle_call({:read, id}, _pid, last_read_at: last_read_at) do
    delay_between_readings = get_env(:collector, :w1_bus_delay_between_readings)
    delay = last_read_at + delay_between_readings - now()
    if delay > 0, do: :timer.sleep(delay)

    {result, new_last_read_at} =
      try do
        {Task.async(fn -> OneWire.read(id) end) |> Task.await(5_000), now()}
      catch
        :exit, {:timeout, _} ->
          delay = @delay_between_readings_on_timeout
          {{:error, "1-wire did not responded for #{id} sensor"}, now() + delay}
      end

    {:reply, result, [last_read_at: new_last_read_at]}
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
  @spec read(id) :: OneWire.read()
  def read(id), do: GenServer.call(__MODULE__, {:read, id}, @read_timeout)

  defp by({:ok, %{id: id}}), do: {0, id}
  defp by(result), do: {1, result}
end
