use Mix.Config

config :interface, InterfaceWeb.Endpoint,
  live_view: [signing_salt: "v2GO6Hj23nU2hWXwZK94aX8BC6sFl9UJ"],
  pubsub: [name: InterfaceWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  render_errors: [view: InterfaceWeb.ErrorView, accepts: ~w(html json)],
  secret_key_base: "iMmeivugBtR9zu1syH9e6A7573D9dVGpzTlb0o/ghwAxLUCqG0ry4mTfl4lKRBr7",
  url: [host: "localhost"]

config :phoenix, :json_library, Jason

import_config "interface/#{Mix.env()}.exs"
