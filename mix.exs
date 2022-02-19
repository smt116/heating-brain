defmodule HeatingBrain.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :heating_brain,
      compilers: [:phoenix] ++ Mix.compilers(),
      deps: deps(),
      dialyzer: dialyzer(),
      elixir: "~> 1.13",
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
      extra_applications: [:logger, :runtime_tools],
      included_applications: [:mnesia],
      mod: {HeatingBrain.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:jason, "~> 1.3"},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.5"},
      {:stream_data, "~> 0.5", only: [:dev, :test], runtime: false},
      {:tzdata, "~> 1.1"}
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

  defp version, do: "1.0.0-#{Mix.env()}+#{String.slice(git_sha(), 0, 9)}"

  defp git_sha, do: File.dir?(".git") |> git_sha()
  defp git_sha(true), do: ({_, 0} = System.cmd("git", ["rev-parse", "HEAD"])) |> elem(0)
  defp git_sha(_), do: File.read!("VERSION_SHA") |> String.trim()
end
