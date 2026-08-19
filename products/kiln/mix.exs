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
      {:exqlite, "~> 0.39"},
      # Bounded MiniMax M3 provider transport (KILN-M0-01 narrow scope).
      # Finch v0.20 is the smallest dependency that satisfies the accepted
      # combined property: status available before/during body processing
      # + incremental bounded body receipt + ability to terminate receipt
      # when the byte limit is crossed. OTP :httpc cannot satisfy both.
      # Mint is transitive; castore was removed in v0.19.0.
      {:finch, "~> 0.20"},
      # M12-D WP-07: bounded Kiln daemon (HTTP + WebSocket). Plug.Cowboy is
      # the smallest Erlang HTTP server with built-in WebSocket upgrade.
      # Avoided full Phoenix framework to keep bounded machinery surface
      # narrow; per-method scope + bounded reconnect + per-entity streams
      # implemented directly in Kiln.Service (Pathfinder WP-02).
      {:plug_cowboy, "~> 2.5"},
      # M12-D WP-07: bounded JSON encoding for bounded RPC payloads.
      # Jason is canonical Elixir JSON; bounded alternative to Poison.
      {:jason, "~> 1.4"}
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
