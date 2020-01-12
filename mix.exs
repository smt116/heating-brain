defmodule Brain.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      apps_path: "apps",
      deps: deps(),
      dialyzer: dialyzer(),
      releases: releases(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  defp aliases do
    [
      check: [
        "compile",
        "format --check-formatted",
        "dialyzer",
        "hex.audit",
        "credo suggest --all"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.1", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:stream_data, "~> 0.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mnesia],
      plt_add_deps: :transitive,
      flags: [
        :error_handling,
        :race_conditions,
        :underspecs
      ]
    ]
  end

  defp releases do
    [
      brain: [
        applications: [
          collector: :permanent,
          mnesia: :load,
          runtime_tools: :permanent,
          interface: :permanent
        ]
      ]
    ]
  end
end
