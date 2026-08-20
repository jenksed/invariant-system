# M1 probe runtime — boot Kiln.Daemon with bounded config for the
# M1 integration probe. Reads config from env: PORT, SCOPED_TOKENS
# (JSON map of token → scope), KILN_HOME (state directory).
#
# Started by the bash orchestrator as:
#
#   elixir --erl "-detached" -S mix run --no-halt scripts/m1_kiln_runtime.exs
#
# The orchestrator waits for /healthz on $PORT before invoking the
# probe, and signals shutdown via SIGTERM on exit.

state_dir = System.get_env("KILN_HOME") || raise "KILN_HOME required"
port = (System.get_env("KILN_PORT") || "41234") |> String.to_integer()

Application.put_env(:kiln, :state_path, Path.join(state_dir, "state.sqlite3"))
Application.put_env(:kiln, :artifact_root, Path.join(state_dir, "artifacts"))

tokens_json = System.get_env("SCOPED_TOKENS") || "{}"
tokens_map =
  tokens_json
  |> Jason.decode!()
  |> Map.new(fn {k, v} -> {k, v} end)

Application.put_env(:kiln, :scoped_tokens, tokens_map)

# Boot Kiln's optional children (Activity.Hub) plus the bounded
# store and the daemon. Mix run has already started
# Kiln.Application before this script ran, so the Store child (which
# is conditional on :state_path) was not included; start it now.
{:ok, _} = Application.ensure_all_started(:kiln)
{:ok, _store} =
  Kiln.Store.start_link(
    path: Path.join(state_dir, "state.sqlite3"),
    name: Kiln.Store.Connection
  )

{:ok, _} = Kiln.Daemon.start_link(port: port)

# Block forever; the orchestrator SIGTERMs us when done.
receive do
  _ -> :ok
end
