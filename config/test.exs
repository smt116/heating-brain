import Config

config :logger, :console, level: :warn

config :mnesia, tables_storage: :ram_copies

config :stream_data,
  initial_size: 10,
  max_run_time: 1000,
  max_runs: 100
