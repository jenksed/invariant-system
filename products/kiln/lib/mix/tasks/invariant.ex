defmodule Mix.Tasks.Invariant do
  @moduledoc """
  Invariant — bounded Kiln daemon task (M12-D WP-07 + WP-08 wire-up).

  Usage:
    mix invariant serve [--port N] [--state-path PATH]   Start bounded Kiln daemon
    mix invariant stop                                   Stop the bounded Kiln daemon

  Monorepo-level commands (status, doctor, check, test) are the root
  `./invariant` script, not this Kiln-local mix task.

  WP-08: when `--state-path` or `KILN_STATE_PATH` is set, the daemon
  supervises the bounded Store, runs `Kiln.Restart.reconstruct/1` at
  boot, and surfaces orphan/unknown status before accepting RPC.
  Without `state_path`, the daemon boots in read-only mode (project.list /
  healthz only — Workflow-backed methods return E_STORE_UNAVAILABLE via
  `Kiln.Workflow.store_conn/0`).
  """

  use Mix.Task

  alias Kiln.{Daemon, Store}

  @shortdoc "Bounded Kiln daemon (serve/stop)"

  @impl Mix.Task
  def run(args) do
    {opts, args, _invalid} =
      OptionParser.parse(args,
          switches: [port: :integer, host: :string, state_path: :string],
          aliases: [p: :port, s: :state_path]
        )

    case args do
      ["serve" | _] -> start_daemon(opts)
      ["stop" | _] -> stop_daemon()
      _ -> print_help()
    end
  end

  defp start_daemon(opts) do
    configure_state_path(opts)
    Mix.Task.run("app.start")
    load_scoped_tokens_from_env()
    surface_state_at_boot()
    port = Keyword.get(opts, :port, 4000)
    IO.puts("Starting bounded Kiln daemon at http://localhost:#{port}")

    case Daemon.start_link(port: port) do
      {:ok, _pid} ->
        # Bounded daemon runs until killed (SIGTERM/SIGINT) or `mix invariant stop`.
        Process.sleep(:infinity)

      {:error, reason} ->
        Mix.raise("failed to start bounded Kiln daemon: #{inspect(reason)}")
    end
  end

  # WP-08: `--state-path` (CLI) or `KILN_STATE_PATH` (env) configures the
  # bounded Store before `Mix.Task.run("app.start")` so the supervisor in
  # `lib/kiln/application.ex:28-33` registers `Kiln.Store.Connection` as a
  # child. The Store is OPTIONAL — without a path the daemon serves
  # read-only placeholders (project.list / healthz) and any Workflow-backed
  # call returns `E_STORE_UNAVAILABLE` from `Kiln.Workflow.store_conn/0`.
  defp configure_state_path(opts) do
    state_path =
      Keyword.get(opts, :state_path) || System.get_env("KILN_STATE_PATH")

    case state_path do
      nil ->
        IO.puts(
          "Kiln state: disabled (no --state-path / KILN_STATE_PATH; read-only mode)"
        )

        :ok

      "" ->
        IO.puts(
          "Kiln state: disabled (empty --state-path; read-only mode)"
        )

        :ok

      path ->
        Application.put_env(:kiln, :state_path, path)
    end
  end

  # WP-08: invoke `Kiln.Restart.reconstruct/1` at boot when the Store is
  # supervised. Surface orphan/unknown status before accepting any RPC so
  # operators can SEE the reconstructed state. Fail-closed on
  # `:multiple_sessions` (per restart.ex:54-57) — first-month shape expects
  # exactly one Session or empty; any other state blocks boot rather than
  # silently picking one.
  defp surface_state_at_boot do
    case Process.whereis(Kiln.Store.Connection) do
      nil ->
        :ok

      conn when is_pid(conn) ->
        case Store.reconstruct(conn) do
          {:ok, :empty} ->
            IO.puts("Kiln state: empty (no Sessions in journal)")
            :ok

          {:ok, reconstruction} ->
            orphaned_flag =
              if reconstruction.orphaned, do: " ORPHANED", else: ""

            IO.puts(
              "Kiln state: session=#{reconstruction.session_id} " <>
                "revision=#{reconstruction.session_revision} " <>
                "cache=#{inspect(reconstruction.cache_status)}" <>
                orphaned_flag
            )

            if reconstruction.orphaned do
              unknowns = reconstruction.projection["unknowns"] || []

              IO.puts(
                "Kiln state: #{length(unknowns)} unknown operation(s) classified as orphaned"
              )
            end

            :ok

          {:error, %{code: :multiple_sessions, detail: detail}} ->
            Mix.raise(
              "Kiln state: refused to start — #{detail.count} Sessions in journal " <>
                "(first-month shape expects 0..1); refusing to silently pick one"
            )

          {:error, %{session_id: session_id, block: block}} ->
            Mix.raise(
              "Kiln state: reconstruction blocked for session #{session_id}: #{inspect(block)}"
            )

          {:error, %{code: code, detail: detail}} ->
            Mix.raise(
              "Kiln state: reconstruction failed: #{inspect(code)} detail=#{inspect(detail)}"
            )
        end
    end
  end

  # Bounded scoped tokens are injected at runtime via the environment, never
  # hardcoded in source. Format: KILN_SCOPED_TOKENS="token1:scope1,token2:scope2"
  # (scope strings contain ":" so each pair splits on the first ":" only).
  defp load_scoped_tokens_from_env do
    case System.get_env("KILN_SCOPED_TOKENS") do
      nil ->
        :ok

      "" ->
        :ok

      raw ->
        tokens =
          raw
          |> String.split(",", trim: true)
          |> Map.new(fn pair ->
            case String.split(pair, ":", parts: 2) do
              [token, scope] -> {token, scope}
              _ -> Mix.raise("malformed KILN_SCOPED_TOKENS pair (expected token:scope)")
            end
          end)

        Application.put_env(:kiln, :scoped_tokens, tokens)
    end
  end

  defp stop_daemon do
    case Process.whereis(Daemon) do
      nil -> IO.puts("No daemon running")
      pid -> Supervisor.stop(pid)
    end
  end

  defp print_help do
    IO.puts("""
    Invariant — bounded Kiln daemon task (M12-D WP-07 + WP-08).

    Subcommands:
      serve [--port N] [--state-path PATH]   Start bounded Kiln daemon
      stop                                   Stop daemon

    Monorepo commands (status, doctor, check, test): use ./invariant at the
    repository root.
    """)
  end
end