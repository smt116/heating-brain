import Config

config :collector,
  heating_controller_timer: 60_000,
  read_initial_delay: 1_000,
  read_initial_enabled: true,
  read_interval: 60_000,
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
    {:"28-01187654b6ff", :valve2, 23.5},
    {:"28-0118761f69ff", :valve3, 3.5}
  ]

config :logger, :console, level: :info