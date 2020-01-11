defmodule Collector.Reader do
  @moduledoc """
  The process that periodically reads values from sensors and saves them into the
  storage.
  """

  use GenServer

  require Logger

  import Application, only: [get_env: 2]
  import Collector.OneWireWorker, only: [read_all: 0]
  import Collector.Storage, only: [write: 1]

  alias Collector.Measurement

  @opaque state :: []

  @impl true
  @spec init(state) :: {:ok, state}
  def init(state) do
    if get_env(:collector, :read_initial_enabled) do
      get_env(:collector, :read_initial_delay) |> schedule_next_read_after()
    end

    {:ok, state}
  end

  @spec start_link(list) :: GenServer.on_start()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  @spec handle_info(:read_all, state) :: {:noreply, state}
  def handle_info(:read_all, state) do
    read_all() |> Enum.each(&handle_read_all_result/1)
    get_env(:collector, :read_interval) |> schedule_next_read_after()

    {:noreply, state}
  end

  defp handle_read_all_result({:ok, %Measurement{} = m}), do: write(m)
  defp handle_read_all_result({:error, msg}), do: Logger.error(fn -> msg end)

  defp schedule_next_read_after(interval) do
    Process.send_after(self(), :read_all, interval)
  end
end
