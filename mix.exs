defmodule Kiln.MixProject do
  use Mix.Project

  def project do
    [
      app: :kiln,
      version: "0.1.0-dev",
      elixir: "~> 1.20",
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

  defp deps, do: []

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
