import Config

config :heating_brain,
  filesystem_handler: Collector.FilesystemMock,
  filesystem_process: {Collector.FilesystemMock, []},
  gpio_base_path: "/sys/class/gpio",
  heating_controller_timer: 5_000,
  read_initial_delay: 1_000,
  read_initial_enabled: true,
  read_interval: 10_000,
  relay_controller_timer: 2_000,
  relays_map: [
    {:heating, 21, "out", nil},
    {:pump, 20, "out", nil},
    {:valve1, 0, "out", 39.1},
    {:valve2, 5, "out", 9.7},
    {:valve3, 6, "out", 9.0},
    {:valve4, 13, "out", 15.6},
    {:valve5, 19, "out", 14.8},
    {:valve6, 26, "out", nil}
  ],
  sensors_map: [
    {:"28-01187615e4ff", :living_room, :valve1,
     [
       {Range.new(0, 7), 19.0},
       {Range.new(7, 17), 21.0},
       {Range.new(17, 24), 20.0}
     ]},
    {:"28-01187654b6ff", :case, :valve2, []},
    {:"28-0118761f69ff", :pipe_in, nil, []}
  ],
  timezone: "Europe/Warsaw",
  w1_bus_delay_between_readings: 1_000,
  w1_bus_master1_path: "/sys/bus/w1/devices/w1_bus_master1",
  w1_bus_read_timeout: 20_000

import_config "collector/#{Mix.env()}.exs"
