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
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
