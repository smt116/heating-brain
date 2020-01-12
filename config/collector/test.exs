import Config

config :collector, read_initial_enabled: false

config :mnesia, tables_storage: :ram_copies
