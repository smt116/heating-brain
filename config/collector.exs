import Config

config :collector,
  filesystem_handler: Collector.FilesystemMock,
  filesystem_process: {Collector.FilesystemMock, []},
  gpio_base_path: "/sys/class/gpio",
  heating_controller_timer: 5_000,
  read_initial_delay: 1_000,
  read_initial_enabled: true,
  read_interval: 10_000,
  relay_controller_timer: 2_000,
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
    {:"28-01187615e4ff", :living_room, :valve1, 25.0},
    {:"28-01187654b6ff", :case, :valve2, 23.5},
    {:"28-0118761f69ff", :pipe, :valve3, 3.5}
  ],
  w1_bus_delay_between_readings: 1_000,
  w1_bus_master1_path: "/sys/bus/w1/devices/w1_bus_master1"

config :mnesia,
  dir: 'mnesia/#{Mix.env()}-#{node()}',
  tables_storage: :disc_copies

import_config "collector/#{Mix.env()}.exs"
