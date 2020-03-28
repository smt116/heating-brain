defmodule HeatingBrain.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :heating_brain,
      compilers: [:phoenix] ++ Mix.compilers(),
      deps: deps(),
      dialyzer: dialyzer(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: version()
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

  def application do
    [
      mod: {HeatingBrain.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.1", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.6"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:stream_data, "~> 0.4", only: [:dev, :test], runtime: false},
      {:tzdata, "~> 1.0"}
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

  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/filesystem_mock.ex"]
  defp elixirc_paths(:test), do: ["lib", "test"]

  defp version do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    short_sha = String.slice(sha, 0, 9)
    "1.0.0-#{Mix.env()}.#{short_sha}"
  end
end
