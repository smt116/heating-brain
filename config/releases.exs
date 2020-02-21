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
    {:"28-0118761492ff", :bathroom, :valve3,
     [
       {Range.new(0, 7), 20.0},
       {Range.new(7, 10), 22.0},
       {Range.new(10, 21), 21.0},
       {Range.new(21, 23), 22.0},
       {Range.new(23, 24), 20.0}
     ]},
    {:"28-01187615e4ff", :living_room, :valve1,
     [
       {Range.new(0, 9), 19.0},
       {Range.new(9, 22), 21.0},
       {Range.new(22, 24), 20.0}
     ]},
    {:"28-0118761f69ff", :pipe_in, nil, []},
    {:"28-011876205aff", :office, :valve2,
     [
       {Range.new(0, 7), 19.0},
       {Range.new(7, 16), 22.0},
       {Range.new(16, 19), 21.0},
       {Range.new(19, 24), 19.0}
     ]},
    {:"28-011876213eff", :bedroom, :valve4,
     [
       {Range.new(0, 7), 19.0},
       {Range.new(7, 16), 20.0},
       {Range.new(16, 19), 20.5},
       {Range.new(19, 23), 20.0},
       {Range.new(23, 24), 19.0}
     ]},
    {:"28-0118765246ff", :room, :valve5,
     [
       {Range.new(0, 7), 18.0},
       {Range.new(7, 20), 19.0},
       {Range.new(20, 24), 18.0}
     ]},
    {:"28-01187654b6ff", :case, nil, []}
  ]

config :mnesia,
  backups_directory: "/srv/backups",
  dir: 'mnesia',
  tables_storage: :disc_copies
