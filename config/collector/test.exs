import Config

config :collector,
  read_initial_enabled: false,
  relay_controller_timer: 10,
  relays_map: [
    {:heating, 21, "out"},
    {:pump, 20, "out"},
    {:valve1, 0, "out"},
    {:valve2, 5, "out"}
  ],
  sensors_label_map: [
    "28-01187615e4ff": :living_room,
    "28-0118761f69ff": :bathroom,
    "28-01187654b6ff": :case
  ],
  sensors_map: [
    {:"28-01187615e4ff", :valve1, 21.0},
    {:"28-0118761f69ff", :valve2, 23.5}
  ],
  w1_bus_delay_between_readings: 0

config :mnesia, tables_storage: :ram_copies
