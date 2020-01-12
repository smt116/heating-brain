import Config

config :collector,
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
    {:"28-01187615e4ff", :valve1, 25.0},
    {:"28-01187654b6ff", :valve2, 23.5},
    {:"28-0118761f69ff", :valve3, 3.5}
  ]
