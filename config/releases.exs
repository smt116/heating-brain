import Config

config :collector,
  heating_controller_timer: 120_000,
  read_initial_delay: 1_000,
  read_initial_enabled: true,
  read_interval: 60_000,
  relay_controller_timer: 300_000,
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
  sensors_label_map: [
    "28-0118761f69ff": :pipe,
    "28-01187654b6ff": :case,
    "28-01187615e4ff": :living_room,
    "28-011876205aff": :office,
    "28-0118761492ff": :bathroom,
    "28-011876213eff": :bedroom,
    "28-0118765246ff": :room
  ],
  sensors_map: [
    {:"28-01187615e4ff", :valve1, 21.5},
    {:"28-011876205aff", :valve2, 22.5},
    {:"28-0118761492ff", :valve3, 22.0},
    {:"28-011876213eff", :valve4, 20.0},
    {:"28-0118765246ff", :valve5, 19.5}
  ]

config :mnesia,
  dir: 'mnesia',
  tables_storage: :disc_copies
