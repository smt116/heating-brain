import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:application, :module, :request_id]

import_config "collector.exs"
import_config "interface.exs"
import_config "#{Mix.env()}.exs"
