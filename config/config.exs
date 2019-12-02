import Config

logger_level =
  if Mix.env() === :test do
    :warn
  else
    :debug
  end

gpio_base_path =
  case Mix.env() do
    :dev -> "filesystem/gpio"
    :prod -> "/sys/class/gpio"
    :test -> "test/fixtures/sys/class/gpio"
  end

w1_bus_master1_path =
  case Mix.env() do
    :dev -> "filesystem/1wire"
    :prod -> "/sys/bus/w1/devices/w1_bus_master1"
    :test -> "test/fixtures/sys/bus/w1/devices/w1_bus_master1"
  end

config :collector,
  gpio_base_path: gpio_base_path,
  read_initial_delay: 1_000,
  read_initial_enabled: if(Mix.env() === :test, do: false, else: true),
  read_interval: 10_000,
  relays_map: [
    {:circulation, 21, "out"},
    {:heating, 11, "out"},
    {:pump, 20, "out"},
    {:valve1, 0, "out"},
    {:valve2, 5, "out"},
    {:valve3, 6, "out"},
    {:valve4, 13, "out"},
    {:valve5, 19, "out"},
    {:valve6, 26, "out"}
  ],
  sensors_map: [
    {:"28-01187615e4ff", :valve1, 25.0},
    {:"28-0118761f69ff", :valve2, 23.5}
  ],
  w1_bus_master1_path: w1_bus_master1_path

config :logger, :console,
  level: logger_level,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:application, :module]

config :mnesia,
  dir: 'mnesia/#{Mix.env()}-#{node()}',
  tables_storage: if(Mix.env() === :test, do: :ram_copies, else: :disc_only_copies)

config :stream_data,
  initial_size: 10,
  max_run_time: 1000,
  max_runs: 100
