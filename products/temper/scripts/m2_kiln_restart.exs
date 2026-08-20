# M2-D probe runtime — boot a SECOND Kiln.Daemon against the SAME
# KILN_HOME/state.sqlite3 that the first daemon was using, so the
# probe can prove the canonical projection survives a true OS-process
# kill+restart of the daemon.
#
# Reads: KILN_HOME, KILN_PORT, SCOPED_TOKENS. Blocks forever; the
# orchestrator SIGTERMs us when done.

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

{:ok, _} = Application.ensure_all_started(:kiln)
{:ok, _store} =
  Kiln.Store.start_link(
    path: Path.join(state_dir, "state.sqlite3"),
    name: Kiln.Store.Connection
  )

{:ok, _} = Kiln.Daemon.start_link(port: port)

receive do
  _ -> :ok
end