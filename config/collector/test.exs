import Config

config :collector,
  read_initial_enabled: false,
  relay_controller_timer: 0,
  relays_map: [
    {:heating, 21, "out"},
    {:pump, 20, "out"},
    {:valve1, 0, "out"},
    {:valve2, 5, "out"}
  ],
  sensors_map: [
    {:"28-01187615e4ff", :living_room, :valve1, 21.0},
    {:"28-0118761f69ff", :bathroom, :valve2, 23.5},
    {:"28-01187654b6ff", :case, nil, nil}
  ],
  w1_bus_delay_between_readings: 0

config :mnesia, tables_storage: :ram_copies
