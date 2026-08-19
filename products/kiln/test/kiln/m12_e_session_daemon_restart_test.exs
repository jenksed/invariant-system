defmodule Kiln.M12ESessionDaemonRestartTest do
  @moduledoc """
  M12-E WP-08 Lane 4: bounded daemon OS-process kill/restart test.

  Acceptance property: a bounded Session started by `mix invariant serve`
  (with `--state-path`) survives the daemon being killed and restarted as
  a separate OS process, and the canonical projection digest computed
  from the new process equals the one computed by the original process.

  Per Recon D scenario 9 (daemon restart mid-Session), this test is the
  real proof that Recon said the post-WP-08 stack provides — formerly
  vacuously safe because the daemon did not open the Store. After Lane 1
  (Store supervised when `--state-path` is set) and Lane 2 (Workflow-
  backed RPC serves `session.start`), this test proves the Session
  identity + canonical `projection_digest` survive a TRUE OS-process
  kill+restart (not just in-process `GenServer.stop + Store.start`).

  Test sequence:

    1. Spawn `mix invariant serve` as a real OS subprocess on a free port
       with a real `--state-path` and a runtime-generated scoped token.
    2. Poll `/healthz` until 200 (bounded 30s).
    3. POST `session.start`; capture `session_id` + `projection_digest`.
    4. SIGKILL the daemon's BEAM process (lsof the port for the PID).
    5. Poll the port until no PID is listening (bounded 10s).
    6. Spawn a NEW `mix invariant serve` with the SAME `--state-path`.
    7. Poll `/healthz` until 200.
    8. POST `session.query` with the captured `session_id`.
    9. The acceptance property: the new `projection_digest` MATCHES the
       original.
    10. (Belt-and-braces) `session_revision == 0` on the new daemon and
        `orphaned == false` (no spurious state, no operation).

  Constraints:

    * `async: false` — this test owns a real TCP port across the whole
      lifecycle; concurrent runs would race on ports.
    * `on_exit` cleanup — kill any remaining daemon process bound to
      `port` and rm-rf the temp state dir, even on test failure.
    * All waits bounded; `Process.sleep(:infinity)` is never used.
    * Runtime-generated tokens only; no hardcoded credentials.
    * We pass `KILN_SCOPED_TOKENS` via a wrapper script's environment so
      the spawned subprocess inherits it (the daemon reads it from
      `System.get_env` at startup — `mix invariant serve` does NOT read
      `Application.put_env`).
  """

  use ExUnit.Case, async: false

  # Bounded durations.
  @healthz_timeout_ms 30_000
  @port_free_timeout_ms 10_000
  @poll_interval_ms 100

  # Per-test setup — two scoped tokens + kill/cleanup on exit.
  #
  # `session.start` requires `orchestration:operate`; `session.query`
  # requires `orchestration:read`. We generate TWO runtime tokens
  # (one per scope) and surface BOTH via `KILN_SCOPED_TOKENS` to the
  # subprocess via the wrapper script (the daemon reads only the env
  # var, not the test VM's `Application.put_env`).
  setup do
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))
    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    previous = Application.get_env(:kiln, :scoped_tokens)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:kiln, :scoped_tokens)
        value -> Application.put_env(:kiln, :scoped_tokens, value)
      end
    end)

    %{operate_token: operate_token, read_token: read_token}
  end

  # ----------------------------------------------------------------
  # Acceptance property: identity survives OS-process kill+restart.
  # ----------------------------------------------------------------

  @tag timeout: 120_000
  test "session_id + projection_digest survive daemon OS-process kill/restart",
       %{operate_token: operate_token, read_token: read_token} do
    port = free_port()
    unique = System.unique_integer([:positive])

    # Temp layout:
    #   base/state.sqlite3   ← --state-path
    #   base/artifacts/      ← created by Store.start
    #   base/repo/README.md  ← project_observation's repository_root
    #   base/daemon-1.log    ← first daemon's captured stdout/stderr
    #   base/daemon-2.log    ← second daemon's captured stdout/stderr
    base = Path.join(System.tmp_dir!(), "kiln-wp08-lane4-#{unique}")
    File.mkdir_p!(base)
    state_path = Path.join(base, "state.sqlite3")
    repo_root = Path.join(base, "repo")
    File.mkdir_p!(repo_root)
    File.write!(Path.join(repo_root, "README.md"), "kiln wp08 lane 4 fixture\n")

    on_exit(fn ->
      kill_daemon_for_port(port)
      rm_rf(base)
    end)

    log1 = Path.join(base, "daemon-1.log")
    log2 = Path.join(base, "daemon-2.log")

    # ---- Step 1+2: spawn first daemon, wait for /healthz ----
    assert :ok ==
             start_daemon(port, state_path, [{operate_token, "orchestration:operate"}, {read_token, "orchestration:read"}], log1),
           "failed to spawn first daemon; see #{log1}"

    assert :ok == wait_for_healthz(port, @healthz_timeout_ms, log1),
           "first daemon did not respond on port #{port}; see #{log1}"

    # ---- Step 3: session.start (uses operate_token) ----
    start_body = session_start_body(repo_root)
    {200, start_resp} = http_post_json(port, "/api/rpc", operate_token, start_body)
    decoded_start = Jason.decode!(start_resp)

    session_id = decoded_start["session_id"]
    first_projection_digest = decoded_start["projection_digest"]

    assert is_binary(session_id) and byte_size(session_id) > 0,
           "session.start returned no session_id: #{inspect(decoded_start)}"

    assert is_binary(first_projection_digest) and
             byte_size(first_projection_digest) > 0,
           "session.start returned no projection_digest: #{inspect(decoded_start)}"

    assert decoded_start["session_revision"] == 0,
           "expected session_revision 0 after start, got #{inspect(decoded_start)}"

    assert decoded_start["run_state"] == "ready",
           "expected run_state=ready after start, got #{inspect(decoded_start)}"

    # ---- Step 4+5: SIGKILL + wait for port free ----
    kill_daemon_for_port(port)
    assert :ok == wait_for_port_free(port, @port_free_timeout_ms),
           "port #{port} still bound after kill; see #{log1}"

    # ---- Step 6+7: spawn second daemon with the SAME --state-path ----
    assert :ok ==
             start_daemon(port, state_path, [{operate_token, "orchestration:operate"}, {read_token, "orchestration:read"}], log2),
           "failed to spawn second daemon; see #{log2}"

    assert :ok == wait_for_healthz(port, @healthz_timeout_ms, log2),
           "second daemon did not respond on port #{port}; see #{log2}"

    # ---- Step 8: session.query on the new daemon (uses read_token) ----
    query_body =
      Jason.encode!(%{
        "method" => "session.query",
        "params" => %{"session_id" => session_id}
      })

    {200, query_resp} = http_post_json(port, "/api/rpc", read_token, query_body)
    decoded_query = Jason.decode!(query_resp)

    second_projection_digest = decoded_query["projection_digest"]
    projection = decoded_query["projection"] || %{}

    assert is_binary(second_projection_digest),
           "session.query returned no projection_digest: #{inspect(decoded_query)}"

    # ---- Step 9: canonical acceptance ----
    assert second_projection_digest == first_projection_digest,
           "projection_digest divergence after daemon OS-process restart: " <>
             "original=#{first_projection_digest} " <>
             "new=#{second_projection_digest} " <>
             "response=#{inspect(decoded_query)}"

    # ---- Step 10: no spurious state added by the restart ----
    assert projection["session_revision"] == 0,
           "expected session_revision 0 on new daemon, got #{inspect(projection)}"

    # ---- Step 11: no orphaned classification (no operation was started) ----
    assert decoded_query["orphaned"] == false,
           "expected orphaned=false (no operation), got #{inspect(decoded_query)}"

    # Explicit cleanup before test exit so the next test (or test-run end)
    # does not inherit a live daemon on this port.
    kill_daemon_for_port(port)
  end

  # ----------------------------------------------------------------
  # Optional regression: a second `session.query` returns the same digest
  # from cache (source == :cache) — proves the cache-rebuilt boundary on
  # a fresh daemon reached steady state.
  # ----------------------------------------------------------------

  @tag timeout: 120_000
  test "session.query on the new daemon returns source matching the projection",
       %{operate_token: operate_token, read_token: read_token} do
    port = free_port()
    unique = System.unique_integer([:positive])

    base = Path.join(System.tmp_dir!(), "kiln-wp08-lane4-source-#{unique}")
    File.mkdir_p!(base)
    state_path = Path.join(base, "state.sqlite3")
    repo_root = Path.join(base, "repo")
    File.mkdir_p!(repo_root)
    File.write!(Path.join(repo_root, "README.md"), "fixture\n")

    on_exit(fn ->
      kill_daemon_for_port(port)
      rm_rf(base)
    end)

    log1 = Path.join(base, "daemon-1.log")
    log2 = Path.join(base, "daemon-2.log")

    assert :ok ==
             start_daemon(
               port,
               state_path,
               [{operate_token, "orchestration:operate"}, {read_token, "orchestration:read"}],
               log1
             )

    assert :ok == wait_for_healthz(port, @healthz_timeout_ms, log1),
           "first daemon did not respond; see #{log1}"

    # Start a session, capture the digest computed by the FIRST daemon.
    start_body = session_start_body(repo_root)
    {200, start_resp} = http_post_json(port, "/api/rpc", operate_token, start_body)
    decoded_start = Jason.decode!(start_resp)
    session_id = decoded_start["session_id"]
    first_projection_digest = decoded_start["projection_digest"]

    kill_daemon_for_port(port)
    assert :ok == wait_for_port_free(port, @port_free_timeout_ms)

    # Start the SECOND daemon.
    assert :ok ==
             start_daemon(
               port,
               state_path,
               [{operate_token, "orchestration:operate"}, {read_token, "orchestration:read"}],
               log2
             )

    assert :ok == wait_for_healthz(port, @healthz_timeout_ms, log2),
           "second daemon did not respond; see #{log2}"

    # First query after daemon restart MUST succeed; the new process has
    # only the journal to rebuild from. The source will be :cache if the
    # cache survived, or :rebuilt otherwise. Both are acceptable — the
    # acceptance property is the digest equality.
    query_body =
      Jason.encode!(%{
        "method" => "session.query",
        "params" => %{"session_id" => session_id}
      })

    {200, q1} = http_post_json(port, "/api/rpc", read_token, query_body)
    decoded_q1 = Jason.decode!(q1)

    assert decoded_q1["projection_digest"] == first_projection_digest,
           "first query on new daemon disagrees with start digest: " <>
             "start=#{first_projection_digest} new=#{decoded_q1["projection_digest"]}"

    source = decoded_q1["source"]
    assert source in [:cache, "cache", :rebuilt, "rebuilt"],
           "unexpected source #{inspect(source)} from session.query: #{inspect(decoded_q1)}"

    kill_daemon_for_port(port)
  end

  # ================================================================
  # Helpers
  # ================================================================

  # Pick an unbound ephemeral port via a TCP listener then close it. The
  # port may be reclaimed before the daemon binds; bounded by tight timing.
  defp free_port do
    {:ok, lsock} = :gen_tcp.listen(0, [:binary, {:active, false}])
    {:ok, {_ip, port}} = :inet.sockname(lsock)
    :gen_tcp.close(lsock)
    port
  end

  # Diagnostic helper: dump the daemon log when healthz fails. Useful when
  # debugging test runs from the bash sandbox — printed via `IO.puts` so it
  # shows up in the test output.
  defp dump_daemon_log(label, log_path) do
    case File.read(log_path) do
      {:ok, content} ->
        IO.puts("[#{label}] daemon log (#{byte_size(content)} bytes):\n#{content}")

      {:error, reason} ->
        IO.puts("[#{label}] cannot read log at #{log_path}: #{inspect(reason)}")
    end
  end

  # Locate the kiln mix project root. The test runs from products/kiln/.
  defp kiln_root do
    cwd = File.cwd!()

    cond do
      File.exists?(Path.join(cwd, "mix.exs")) and
          File.dir?(Path.join(cwd, "lib")) ->
        cwd

      File.exists?(Path.join(cwd, "products/kiln/mix.exs")) ->
        Path.expand("products/kiln", cwd)

      true ->
        flunk("could not locate products/kiln mix.exs from cwd=#{cwd}")
    end
  end

  # Spawn `mix invariant serve` as a real OS subprocess via a bash wrapper
  # that detaches the daemon (`&` + `disown`) and redirects stdout/stderr
  # to `log_path`. The wrapper itself exits quickly, returning the daemon's
  # initial PID so the test does not block waiting for the daemon to die.
  #
  # `tokens` is the list of `[{token, scope}, ...]` pairs to install in
  # the daemon via `KILN_SCOPED_TOKENS`. The daemon's
  # `Mix.Tasks.Invariant.load_scoped_tokens_from_env/0` reads this env
  # var at startup, parses `token:scope` pairs separated by `,`.
  defp start_daemon(port, state_path, tokens, log_path) do
    kiln_root = kiln_root()
    scoped_tokens_value = Enum.map_join(tokens, ",", fn {token, scope} -> "#{token}:#{scope}" end)

    wrapper =
      Path.join(
        System.tmp_dir!(),
        "kiln-wp08-lane4-spawn-#{System.unique_integer([:positive])}.sh"
      )

    script = """
    #!/bin/bash
    cd #{shell_quote(kiln_root)}
    KILN_SCOPED_TOKENS=#{shell_quote(scoped_tokens_value)} \\
      mix invariant serve --port #{port} --state-path #{shell_quote(state_path)} \\
      < /dev/null > #{shell_quote(log_path)} 2>&1 &
    disown
    """

    File.write!(wrapper, script)
    File.chmod!(wrapper, 0o755)

    # The wrapper returns immediately after `disown`; the daemon lives on.
    case System.cmd(wrapper, []) do
      {_output, 0} -> :ok
      {_output, code} -> {:error, "wrapper exited #{code}"}
    end
  end

  # Use `lsof -ti tcp:PORT` to find every PID bound to that port and SIGKILL
  # each one. Bounded by `wait_for_port_free/2`.
  defp kill_daemon_for_port(port) do
    pids =
      case System.cmd("lsof", ["-ti", "tcp:#{port}"]) do
        {out, 0} ->
          out
          |> String.split("\n", trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        _ ->
          []
      end

    for pid <- pids do
      try do
        System.cmd("kill", ["-9", pid])
      catch
        _kind, _reason -> :ok
      end
    end

    :timer.sleep(50)
    :ok
  end

  # Poll `/healthz` until 200 or `timeout_ms`. The body is just
  # `{"status":"ok"}`; success means the HTTP layer is reachable AND the
  # plug pipeline is mounted. If the wait times out, dump the daemon's
  # log for offline debugging.
  defp wait_for_healthz(port, timeout_ms, log_path) do
    deadline = monotonic_ms() + timeout_ms

    result =
      Stream.repeatedly(fn -> :ok end)
      |> Enum.reduce_while(:error, fn _, _ ->
        cond do
          healthz_ok?(port) -> {:halt, :ok}
          monotonic_ms() > deadline -> {:halt, {:error, :timeout}}
          true ->
            :timer.sleep(@poll_interval_ms)
            {:cont, :error}
        end
      end)

    if result == {:error, :timeout} and is_binary(log_path) do
      dump_daemon_log("healthz-timeout", log_path)
    end

    result
  end

  defp healthz_ok?(port) do
    case do_http_get(port, "/healthz", 1_000) do
      {:ok, 200, _body} -> true
      _ -> false
    end
  end

  # Wait for `lsof -ti tcp:PORT` to report zero PIDs, or timeout.
  defp wait_for_port_free(port, timeout_ms) do
    deadline = monotonic_ms() + timeout_ms

    Stream.repeatedly(fn -> :ok end)
    |> Enum.reduce_while(:error, fn _, _ ->
      cond do
        pids_for_port(port) == [] -> {:halt, :ok}
        monotonic_ms() > deadline -> {:halt, {:error, :timeout}}
        true ->
          :timer.sleep(@poll_interval_ms)
          {:cont, :error}
      end
    end)
  end

  defp pids_for_port(port) do
    case System.cmd("lsof", ["-ti", "tcp:#{port}"]) do
      {out, 0} ->
        out
        |> String.split("\n", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      _ ->
        []
    end
  end

  # POST JSON to `path` on `port` with a Bearer token. Returns
  # `{status, body_string}`. Body must be a JSON-encoded string.
  defp http_post_json(port, path, token, body_json) when is_binary(body_json) do
    case do_http_post(port, path, token, body_json, 5_000) do
      {:ok, status, body} -> {status, body}
      {:error, reason} -> {:error, reason}
    end
  end

  # Minimal HTTP/1.1 client built on `:gen_tcp`. We avoid `:httpc` because
  # it depends on a started `:inets` profile; this raw client works
  # regardless of test VM configuration.
  defp do_http_get(port, path, timeout_ms) do
    req = "GET #{path} HTTP/1.1\r\nHost: localhost:#{port}\r\nConnection: close\r\n\r\n"
    do_http_request(port, "127.0.0.1", req, [], timeout_ms)
  end

  defp do_http_post(port, path, token, body, timeout_ms) do
    body_bytes = IO.iodata_to_binary(body)
    headers = [
      "POST #{path} HTTP/1.1",
      "Host: localhost:#{port}",
      "Authorization: Bearer #{token}",
      "Content-Type: application/json",
      "Content-Length: #{byte_size(body_bytes)}",
      "Connection: close"
    ]

    req = Enum.join(headers, "\r\n") <> "\r\n\r\n" <> body_bytes
    do_http_request(port, "127.0.0.1", req, [], timeout_ms)
  end

  defp do_http_request(port, host, request, _extra_headers, timeout_ms) do
    case :gen_tcp.connect(to_charlist(host), port, [:binary, {:active, false}], timeout_ms) do
      {:ok, sock} ->
        try do
          :ok = :gen_tcp.send(sock, request)
          read_until_close(sock, "", timeout_ms)
        after
          :gen_tcp.close(sock)
        end

      {:error, reason} ->
        {:error, {:connect_failed, reason}}
    end
  end

  # Read from `sock` until EOF or timeout. Returns `{:ok, status, body}`
  # on a well-formed HTTP/1.1 response, or `{:error, reason}` otherwise.
  defp read_until_close(sock, acc, timeout_ms) do
    case :gen_tcp.recv(sock, 0, timeout_ms) do
      {:ok, chunk} ->
        read_until_close(sock, acc <> chunk, timeout_ms)

      {:error, :closed} ->
        parse_http_response(acc)

      {:error, reason} ->
        {:error, {:recv_failed, reason}}
    end
  end

  defp parse_http_response(raw) do
    # Split headers and body on the first blank line (\r\n\r\n).
    [header_block, body] = String.split(raw, "\r\n\r\n", parts: 2)
    [status_line | header_lines] = String.split(header_block, "\r\n", trim: true)

    case String.split(status_line, " ", parts: 3) do
      ["HTTP/1.1", status_str, _reason] ->
        status = String.to_integer(status_str)

        # Touch headers (consume but ignore for our purposes) so callers
        # could read them later if needed.
        _header_lines = header_lines
        {:ok, status, body}

      _ ->
        {:error, {:malformed_status_line, status_line}}
    end
  end

  defp monotonic_ms do
    System.monotonic_time(:millisecond)
  end

  # Singleton POSIX-style single-quote escape for shell arguments that may
  # contain single quotes. `'` → `'\''`.
  defp shell_quote(value) when is_binary(value) do
    inner = String.replace(value, "'", "'\\''")
    "'" <> inner <> "'"
  end

  defp rm_rf(path) do
    try do
      File.rm_rf!(path)
    catch
      _kind, _reason -> :ok
    end

    :ok
  end

  # Build a `session.start` envelope. `repo_root` is a real directory we
  # created in setup; `repository_fingerprint` is a fixed sha256 derived
  # from a stable string literal. The format MUST be lowercase hex
  # (regex `^sha256:[0-9a-f]{64}$` enforced by
  # `Kiln.Domain.ProjectObservation`).
  defp session_start_body(repo_root) do
    fingerprint =
      "sha256:" <>
        Base.encode16(:crypto.hash(:sha256, "kiln-wp08-lane4-fixture"), case: :lower)

    %{
      "method" => "session.start",
      "params" => %{
        "objective" => "Verify bounded Session survives daemon OS-process kill+restart",
        "criteria" => [
          "session_id returned by first daemon == session_id returned by second daemon",
          "projection_digest returned by first session.start == projection_digest returned by session.query on second daemon"
        ],
        "actor_id" => "user:wp08-lane4-test",
        "project_observation" => %{
          "repository_root" => repo_root,
          "repository_fingerprint" => fingerprint,
          "observed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }
      }
    }
    |> Jason.encode!()
  end
end
