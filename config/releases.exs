import Config

config :collector,
  heating_controller_timer: 120_000,
  heating_controller_required_load: 16.0,
  read_initial_delay: 5_000,
  read_initial_enabled: true,
  read_interval: 120_000,
  relay_controller_timer: 600_000,
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
    {:"28-0118771440ff", :bathroom, :valve3,
     [
       {Range.new(0, 6), 19.0},
       {Range.new(6, 9), 21.5},
       {Range.new(9, 19), 21.0},
       {Range.new(19, 20), 21.5},
       {Range.new(20, 24), 20.0}
     ]},
    {:"28-0119504469ff", :living_room, :valve1,
     [
       {Range.new(0, 6), 19.0},
       {Range.new(6, 20), 21.0},
       {Range.new(20, 24), 20.0}
     ]},
    {:"28-01187654b6ff", :pipe_in, nil, []},
    {:"28-011876205aff", :office, :valve2,
     [
       {Range.new(0, 6), 19.0},
       {Range.new(6, 8), 21.0},
       {Range.new(8, 12), 22.0},
       {Range.new(12, 19), 21.0},
       {Range.new(19, 24), 19.0}
     ]},
    {:"28-0118761492ff", :bedroom, :valve4,
     [
       {Range.new(0, 6), 18.5},
       {Range.new(6, 7), 21.0},
       {Range.new(7, 20), 19.5},
       {Range.new(20, 24), 18.5}
     ]},
    {:"28-0118765246ff", :room, :valve5,
     [
       {Range.new(0, 6), 18.5},
       {Range.new(6, 7), 19.0},
       {Range.new(7, 24), 18.5}
     ]}
  ],
  w1_bus_delay_between_readings: 3_000

config :mnesia,
  backups_directory: "/srv/backups",
  dir: 'mnesia',
  tables_storage: :disc_copies
