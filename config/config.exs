import Config

[filesystem_handler, filesystem_process] =
  if Mix.env() === :prod do
    [File, nil]
  else
    [Collector.FilesystemMock, {Collector.FilesystemMock, []}]
  end

logger_level =
  if Mix.env() === :test do
    :warn
  else
    :debug
  end

config :collector,
  filesystem_handler: filesystem_handler,
  filesystem_process: filesystem_process,
  gpio_base_path: "/sys/class/gpio",
  heating_controller_timer: 5_000,
  read_initial_delay: 1_000,
  read_initial_enabled: if(Mix.env() === :test, do: false, else: true),
  read_interval: 15_000,
  relay_controller_timer: 10,
  relays_map: [
    {:heating, 21, "out"},
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
    {:"28-01187654b6ff", :valve2, 23.5},
    {:"28-0118761f69ff", :valve3, 3.5}
  ],
  w1_bus_master1_path: "/sys/bus/w1/devices/w1_bus_master1"

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
