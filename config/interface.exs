use Mix.Config

config :interface, InterfaceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iMmeivugBtR9zu1syH9e6A7573D9dVGpzTlb0o/ghwAxLUCqG0ry4mTfl4lKRBr7",
  render_errors: [view: InterfaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: InterfaceWeb.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, :json_library, Jason

import_config "interface/#{Mix.env()}.exs"
