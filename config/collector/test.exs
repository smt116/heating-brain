import Config

config :collector,
  read_initial_enabled: false,
  relay_controller_timer: 0,
  relays_map: [
    {:heating, 21, "out", nil},
    {:pump, 20, "out", nil},
    {:valve1, 0, "out", 3.5},
    {:valve2, 5, "out", 3.5}
  ],
  sensors_map: [
    {:"28-01187615e4ff", :living_room, :valve1,
     [
       {Range.new(0, 7), 19.0},
       {Range.new(7, 17), 21.0},
       {Range.new(17, 24), 20.0}
     ]},
    {:"28-01187654b6ff", :bathroom, :valve2,
     [
       {Range.new(0, 7), 20.5},
       {Range.new(7, 17), 21.5},
       {Range.new(17, 22), 22.0},
       {Range.new(17, 24), 21.0}
     ]},
    {:"28-0118761f69ff", :case, nil, []}
  ],
  w1_bus_delay_between_readings: 0

config :mnesia, tables_storage: :ram_copies
