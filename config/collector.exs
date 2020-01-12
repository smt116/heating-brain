import Config

config :collector,
  filesystem_handler: Collector.FilesystemMock,
  filesystem_process: {Collector.FilesystemMock, []},
  gpio_base_path: "/sys/class/gpio",
  heating_controller_timer: 5_000,
  read_initial_delay: 1_000,
  read_initial_enabled: true,
  read_interval: 15_000,
  relay_controller_timer: 10,
  w1_bus_master1_path: "/sys/bus/w1/devices/w1_bus_master1"

config :mnesia,
  dir: 'mnesia/#{Mix.env()}-#{node()}',
  tables_storage: :disc_only_copies

import_config "collector/#{Mix.env()}.exs"
