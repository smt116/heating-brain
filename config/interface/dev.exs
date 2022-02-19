import Config

config :heating_brain, InterfaceWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../../assets", __DIR__)
    ]
  ]

config :heating_brain, InterfaceWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/interface_web/{live,views}/.*(ex)$",
      ~r"lib/interface_web/templates/.*(eex)$"
    ]
  ]
