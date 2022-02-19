import Config

config :heating_brain, InterfaceWeb.Endpoint,
  live_view: [signing_salt: "v2GO6Hj23nU2hWXwZK94aX8BC6sFl9UJ"],
  pubsub_server: InterfaceWeb.PubSub,
  render_errors: [view: InterfaceWeb.ErrorView, accepts: ~w(html json)],
  secret_key_base: "iMmeivugBtR9zu1syH9e6A7573D9dVGpzTlb0o/ghwAxLUCqG0ry4mTfl4lKRBr7",
  url: [host: "localhost"]

import_config "interface/#{Mix.env()}.exs"
