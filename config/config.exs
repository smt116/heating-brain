import Config

logger_level =
  if Mix.env() === :test do
    :warn
  else
    :debug
  end

w1_bus_master1_path =
  case Mix.env() do
    :dev -> "filesystem/1wire"
    :prod -> "/sys/bus/w1/devices/w1_bus_master1"
    :test -> "test/fixtures/sys/bus/w1/devices/w1_bus_master1"
  end

config :collector,
  read_interval: 10_000,
  read_initial_delay: 1_000,
  read_initial_enabled: if(Mix.env() === :test, do: false, else: true),
  w1_bus_master1_path: w1_bus_master1_path

config :logger, :console,
  level: logger_level,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:application, :module]

config :mnesia, dir: 'mnesia/#{Mix.env()}-#{node()}'

config :stream_data, max_runs: 50
