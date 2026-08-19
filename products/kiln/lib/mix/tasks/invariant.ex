defmodule Mix.Tasks.Invariant do
  @moduledoc """
  Invariant — bounded Kiln daemon task (M12-D WP-07).

  Usage:
    mix invariant serve [--port N]          Start bounded Kiln daemon (M12-D WP-07)
    mix invariant stop                      Stop the bounded Kiln daemon

  Monorepo-level commands (status, doctor, check, test) are the root
  `./invariant` script, not this Kiln-local mix task.
  """

  use Mix.Task

  alias Kiln.Daemon

  @shortdoc "Bounded Kiln daemon (serve/stop)"

  @impl Mix.Task
  def run(args) do
    {opts, args, _invalid} = OptionParser.parse(args, switches: [port: :integer, host: :string])

    case args do
      ["serve" | _] -> start_daemon(opts)
      ["stop" | _] -> stop_daemon()
      _ -> print_help()
    end
  end

  defp start_daemon(opts) do
    Mix.Task.run("app.start")
    load_scoped_tokens_from_env()
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
    Invariant — bounded Kiln daemon task (M12-D WP-07).

    Subcommands:
      serve [--port N]       Start bounded Kiln daemon
      stop                   Stop daemon

    Monorepo commands (status, doctor, check, test): use ./invariant at the
    repository root.
    """)
  end
end
