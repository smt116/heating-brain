use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :interface, InterfaceWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  http: [:inet6, port: 80],
  secret_key_base: "GRPMEDPm+cAqEgriwl2Ucz1LQrepxSB3igJuVsLY9ovVjNIAl",
  url: [host: "brain.local", port: 80]

config :interface, InterfaceWeb.Endpoint, server: true
