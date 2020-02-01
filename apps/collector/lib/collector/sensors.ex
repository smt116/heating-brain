defmodule Collector.Sensors do
  @moduledoc """
  The interface for accessing sensors' readings from the storage. It does not
  interfere with the 1-wire filesystem, and thus the "current values".
  """

  alias Collector.Measurement
  alias Collector.Storage

  @type id :: Measurement.id()
  @type measurement :: Measurement.t()
  @type timestamp :: DateTime.t()
  @type unix_epoch :: pos_integer

  @doc """
  Returns readings for a given sensor.
  """
  @spec select(id, timestamp | unix_epoch) :: list(measurement)
  def select(id, within) when is_atom(id) and is_integer(within) and within > 0 do
    select(id, to_datetime(within))
  end

  def select(id, %DateTime{} = since) when is_atom(id) do
    Storage.select(Measurement, id, since)
  end

  @doc """
  Returns readings for all, defined sensor.
  """
  @spec select(timestamp | unix_epoch) :: list({id, list(measurement)})
  def select(within) when is_integer(within) and within > 0 do
    within |> to_datetime() |> select()
  end

  def select(%DateTime{} = since) do
    Storage.select(Measurement, since)
  end

  defp to_datetime(seconds) when is_integer(seconds) and seconds > 0 do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(-seconds, :second)
  end
end
