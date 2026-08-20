defmodule Temper.MixProject do
  use Mix.Project

  def project do
    [
      app: :temper,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Temper needs the canonical Kiln graph projection to build
      # operator-facing views. The dependency is path-based; the
      # temper-elixir product lives next to kiln in the monorepo
      # and references it via the relative path. A future commit
      # may publish kiln to a hex package.
      {:kiln, path: "../kiln"}
    ]
  end
end
