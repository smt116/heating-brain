import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:application, :module, :request_id]

config :mnesia,
  backups_directory: "/tmp/mnesia_backups",
  dir: 'mnesia/#{Mix.env()}-#{node()}',
  tables_storage: :disc_copies

config :phoenix, :json_library, Jason

import_config "collector.exs"
import_config "interface.exs"
import_config "#{Mix.env()}.exs"
