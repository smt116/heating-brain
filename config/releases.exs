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
  sensors_map: [
    {:"28-0118761492ff", :bathroom, :valve3, 22.0},
    {:"28-01187615e4ff", :living_room, :valve1, 21.5},
    {:"28-0118761f69ff", :pipe_in, nil, nil},
    {:"28-011876205aff", :office, :valve2, 22.5},
    {:"28-011876213eff", :bedroom, :valve4, 20.0},
    {:"28-0118765246ff", :room, :valve5, 19.5},
    {:"28-01187654b6ff", :case, nil, nil}
  ]

config :mnesia,
  dir: 'mnesia',
  tables_storage: :disc_copies
