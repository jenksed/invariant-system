defmodule Kiln.MixProject do
  use Mix.Project

  def project do
    [
      app: :kiln,
      version: "0.1.0-dev",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Kiln.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      # Direct SQLite state store per ADR-0022. The 0.39 line bundles SQLite
      # 3.53.3, which contains the WAL-reset corruption fix from 3.51.3.
      {:exqlite, "~> 0.39"}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test"
      ]
    ]
  end
end
