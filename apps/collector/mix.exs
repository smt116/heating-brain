defmodule Collector.MixProject do
  use Mix.Project

  def project do
    [
      app: :collector,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps: [],
      deps_path: "../../deps",
      elixir: "~> 1.9",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Collector.Application, []}
    ]
  end
end
