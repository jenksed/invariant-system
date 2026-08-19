defmodule Kiln.M12DSessionRpcTest do
  @moduledoc """
  M12-D WP-08 Lane 2: bounded RPC router tests for the session-family methods.

  Acceptance properties (per WP08-WP09-PLAN.md):

    P1 — RPC envelope idempotency field.
      Two `session.start` RPCs with the same `idempotency_key` produce
      the same `session_id` (verified via `Kiln.Workflow.query_session/1`)
      — the second call DOES NOT mint a fresh session.

    P5 — Transport preserves bounded error codes.
      `Kiln.RPC.Router.dispatch/2` MUST NOT flatten `%{code: atom, ...}`
      errors to `E_DISPATCH_FAILED`. Workflow errors (e.g.
      `:invalid_session_id`, `:missing_actor_id`,
      `:invalid_idempotency_key`) and handler errors (e.g.
      `:E_MISSING_FIELDS`) pass through unchanged.

    Session-family methods are in the scope table.
      `session.start/cancel/resume` → `orchestration:operate`
      `session.query/next_actions` → `orchestration:read`

  Pattern mirrors `Kiln.M12DKilnDaemonTest`: bounded scoped tokens are
  generated at runtime (never hardcoded) and injected via
  `Application.put_env(:kiln, :scoped_tokens, ...)` with `on_exit`
  restore. The bounded store connection is started in setup and torn
  down in `on_exit` so the tests do not leak state.
  """

  use ExUnit.Case, async: false

  import Plug.Test

  alias Kiln.{Service, Store, Workflow}
  alias Kiln.RPC.Router

  @now "2026-07-29T13:30:00Z"
  @at ~U[2026-07-29 13:30:00Z]
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    # Tear down any store connection from a prior test.
    stop_registered_store()

    # Snapshot the previous scoped_tokens config so we can restore it on exit.
    previous_tokens = Application.get_env(:kiln, :scoped_tokens)

    # Generate runtime tokens for each scope used in this suite.
    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))

    Application.put_env(
      :kiln,
      :scoped_tokens,
      %{read_token => "orchestration:read", operate_token => "orchestration:operate"}
    )

    # Spin up a fresh bounded store at a unique temp path.
    dir = Path.join(System.tmp_dir!(), "kiln-session-rpc-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "session_rpc_#{System.unique_integer([:positive])}",
        now: @now,
        name: Kiln.Store.Connection
      )

    on_exit(fn ->
      stop_registered_store()

      case previous_tokens do
        nil -> Application.delete_env(:kiln, :scoped_tokens)
        value -> Application.put_env(:kiln, :scoped_tokens, value)
      end

      File.rm_rf!(dir)
    end)

    %{
      read_token: read_token,
      operate_token: operate_token,
      dir: dir,
      store: store
    }
  end

  # ----------------------------------------------------------------
  # P1 — idempotency forward (session.start same key returns same id)
  # ----------------------------------------------------------------

  describe "WP-08 P1 — envelope idempotency_key forward" do
    test "two session.start RPCs with the same idempotency_key produce the same session_id",
         %{operate_token: token} do
      idem_key = "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)

      # First call — mint a fresh session.
      first_body =
        session_start_body(%{
          "idempotency_key" => idem_key
        })

      first_conn =
        conn(:post, "/api/rpc", Jason.encode!(first_body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert first_conn.status == 200,
             "first session.start should succeed; got status=#{first_conn.status} body=#{inspect(first_conn.resp_body)}"

      first_decoded = Jason.decode!(first_conn.resp_body)
      first_session_id = first_decoded["session_id"]
      assert is_binary(first_session_id) and byte_size(first_session_id) > 0

      # Second call — same idempotency_key + same params → must replay.
      second_body =
        session_start_body(%{
          "idempotency_key" => idem_key
        })

      second_conn =
        conn(:post, "/api/rpc", Jason.encode!(second_body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert second_conn.status == 200,
             "second session.start should succeed via replay; got status=#{second_conn.status} body=#{inspect(second_conn.resp_body)}"

      second_decoded = Jason.decode!(second_conn.resp_body)
      second_session_id = second_decoded["session_id"]

      # P1 acceptance: same idempotency_key ⇒ same session_id, NOT a fresh one.
      assert second_session_id == first_session_id,
             "expected the replayed session_id #{first_session_id}, got #{second_session_id}"

      # Independent check: the journal must hold exactly one Session.
      # `query_result()` carries `projection` (which holds `session_revision`),
      # not a top-level `session_revision`.
      assert {:ok, %{session_id: ^first_session_id, projection: projection}} =
               Workflow.query_session(first_session_id)

      assert projection["session_revision"] == 0
    end

    test "two session.start RPCs WITHOUT idempotency_key still work (auto-mint path)",
         %{operate_token: token} do
      first_conn =
        conn(:post, "/api/rpc", Jason.encode!(session_start_body(%{})))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      # Auto-mint path must continue to work after P1 forwarding.
      assert first_conn.status == 200,
             "auto-mint path should succeed; got status=#{first_conn.status} body=#{inspect(first_conn.resp_body)}"
    end
  end

  # ----------------------------------------------------------------
  # P5 — Transport preserves bounded error codes
  # ----------------------------------------------------------------

  describe "WP-08 P5 — bounded error codes pass through unchanged" do
    test "Workflow error code :invalid_session_id survives the HTTP transport",
         %{read_token: token} do
      # session_id "not-a-valid-session" passes the handler's
      # require_string check (non-empty binary) but fails
      # Workflow.require_session_id_format — that path returns
      # %Kiln.Domain.Error{code: :invalid_session_id, ...}.
      body = %{
        "method" => "session.query",
        "params" => %{"session_id" => "not-a-valid-session"}
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 400
      decoded = Jason.decode!(conn.resp_body)
      # P5 acceptance: the Workflow error code is preserved, NOT flattened
      # to E_DISPATCH_FAILED.
      assert decoded["code"] == "invalid_session_id",
             "expected code=invalid_session_id, got #{inspect(decoded)}"
    end

    test "handler error code :E_MISSING_FIELDS survives the HTTP transport",
         %{operate_token: token} do
      # session.start with no `objective` field — the handler's
      # require_all returns E_MISSING_FIELDS BEFORE Workflow is called.
      body = %{
        "method" => "session.start",
        "params" => %{
          "actor_id" => "user:local",
          "criteria" => ["criterion passes"],
          "project_observation" => observation_map()
        }
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 400
      decoded = Jason.decode!(conn.resp_body)
      # P5 acceptance: the handler error code is preserved, NOT flattened
      # to E_DISPATCH_FAILED.
      assert decoded["code"] == "E_MISSING_FIELDS",
             "expected code=E_MISSING_FIELDS, got #{inspect(decoded)}"
    end

    test "Workflow error code :invalid_identifier survives the Router",
         %{operate_token: _token} do
      # session.start with a malformed idempotency_key — the handler's
      # `put_idempotency` passes any binary through, so the request reaches
      # Workflow.normalize_start_opts → optional_idempotency_key_map, which
      # calls `Id.validate(:idempotency, value)` and returns
      # %Kiln.Domain.Error{code: :invalid_identifier, details: %{kind: :idempotency}}
      # for non-empty binary values that don't match the `idem_<32-hex>` shape.
      body = %{
        "method" => "session.start",
        "params" => %{
          "objective" => "Correct one bounded defect",
          "criteria" => ["The focused test passes"],
          "actor_id" => "user:local",
          "project_observation" => observation_map()
        },
        "idempotency_key" => "not-an-idem-key-format"
      }

      result = Router.dispatch("orchestration:operate", body)
      # P5: Workflow's error code is preserved, NOT flattened to
      # E_DISPATCH_FAILED. The atom `:invalid_identifier` with detail
      # `kind: :idempotency` proves the error came from the Workflow
      # validator, not the handler.
      assert {:error,
              %{
                code: :invalid_identifier,
                details: %{kind: :idempotency}
              }} = result
    end
  end

  # ----------------------------------------------------------------
  # Scope enforcement + scope table coverage
  # ----------------------------------------------------------------

  describe "WP-08 Lane 2 — scope table + scope enforcement" do
    test "session.start with orchestration:read returns E_SCOPE_INSUFFICIENT" do
      body = %{
        "method" => "session.start",
        "params" => %{
          "objective" => "objective",
          "criteria" => ["criterion"],
          "actor_id" => "user:local",
          "project_observation" => observation_map()
        }
      }

      assert {:error, %{code: :E_SCOPE_INSUFFICIENT} = err} =
               Router.dispatch("orchestration:read", body)

      assert err.method == "session.start"
    end

    test "session.start with orchestration:operate passes scope (handler may succeed or surface a Workflow error)",
         %{operate_token: token} do
      body = %{
        "method" => "session.start",
        "params" => %{
          "objective" => "Correct one bounded defect",
          "criteria" => ["The focused test passes"],
          "actor_id" => "user:local",
          "project_observation" => observation_map()
        }
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      # Scope must pass — NOT E_SCOPE_INSUFFICIENT. The handler / Workflow
      # may succeed (200) or return a Workflow error code; either is
      # acceptable, as long as it's not a scope rejection.
      decoded = Jason.decode!(conn.resp_body)
      refute decoded["code"] == "E_SCOPE_INSUFFICIENT",
             "scope check must pass for session.start with orchestration:operate; got #{inspect(decoded)}"
    end

    test "session.cancel requires orchestration:operate (read rejected)" do
      body = %{
        "method" => "session.cancel",
        "params" => %{
          "session_id" => "ses_00000000000000000000000000000001",
          "actor_id" => "user:local",
          "expected_session_revision" => 0
        }
      }

      assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} =
               Router.dispatch("orchestration:read", body)
    end

    test "session.resume requires orchestration:operate (read rejected)" do
      body = %{
        "method" => "session.resume",
        "params" => %{
          "session_id" => "ses_00000000000000000000000000000001",
          "actor_id" => "user:local",
          "expected_session_revision" => 0
        }
      }

      assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} =
               Router.dispatch("orchestration:read", body)
    end

    test "session.query requires orchestration:read (operate rejected)" do
      body = %{
        "method" => "session.query",
        "params" => %{"session_id" => "ses_00000000000000000000000000000001"}
      }

      # session.query requires orchestration:read; orchestration:operate
      # does NOT match — scope check fails.
      assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} =
               Router.dispatch("orchestration:operate", body)

      # orchestration:read passes scope (P5 preservation — handler result
      # is returned unchanged). The handler may return :empty or a query
      # result; neither is E_SCOPE_INSUFFICIENT.
      result = Router.dispatch("orchestration:read", body)
      refute match?({:error, %{code: :E_SCOPE_INSUFFICIENT}}, result)
    end

    test "session.query with orchestration:read passes scope (handler returns Workflow response)",
         %{read_token: token} do
      body = %{
        "method" => "session.query",
        "params" => %{"session_id" => "ses_00000000000000000000000000000001"}
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      # The scope check must pass. On a fresh journal, the handler returns
      # `{:ok, :empty}` which JSON-encodes to the bare string `"empty"`
      # (not an object), so we cannot decode it as a map. Verify by
      # status + raw body shape: 200 with `empty`, OR 400 with a non-
      # scope error code. E_SCOPE_INSUFFICIENT is never permitted.
      case {conn.status, conn.resp_body} do
        {200, _body} ->
          :ok

        {400, body} ->
          decoded = Jason.decode!(body)
          refute decoded["code"] == "E_SCOPE_INSUFFICIENT",
                 "scope check must pass for session.query with orchestration:read; got #{inspect(decoded)}"

        other ->
          flunk("unexpected response #{inspect(other)}")
      end
    end

    test "session.next_actions requires orchestration:read (other scopes rejected)" do
      body = %{
        "method" => "session.next_actions",
        "params" => %{"session_id" => "ses_00000000000000000000000000000001"}
      }

      assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} =
               Router.dispatch("orchestration:operate", body)

      refute match?(
               {:error, %{code: :E_SCOPE_INSUFFICIENT}},
               Router.dispatch("orchestration:read", body)
             )
    end
  end

  # ----------------------------------------------------------------
  # Malformed envelope still rejected
  # ----------------------------------------------------------------

  describe "WP-08 Lane 2 — malformed envelope handling" do
    test "POST /api/rpc with no method key returns E_MALFORMED_REQUEST",
         %{operate_token: token} do
      conn =
        conn(:post, "/api/rpc", ~s({"foo": "bar"}))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 400
      decoded = Jason.decode!(conn.resp_body)
      assert decoded["code"] == "E_MALFORMED_REQUEST",
             "expected code=E_MALFORMED_REQUEST, got #{inspect(decoded)}"
    end
  end

  # ----------------------------------------------------------------
  # Regression — project.list still works
  # ----------------------------------------------------------------

  describe "WP-08 Lane 2 — no regression on existing placeholder methods" do
    test "project.list with orchestration:read still returns 200 + bounded projects list",
         %{read_token: token} do
      conn =
        conn(:post, "/api/rpc", ~s({"method":"project.list","params":{}}))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 200
      decoded = Jason.decode!(conn.resp_body)
      assert decoded == %{"projects" => []}
    end
  end

  # ----------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------

  # Stable project_observation map that satisfies
  # `Kiln.Domain.ProjectObservation.new/1` validation.
  # JSON-decoded envelopes always carry string keys, so this helper emits
  # string keys directly. `observed_at` is an ISO 8601 string because
  # JSON round-tripping cannot preserve a `%DateTime{}` struct.
  defp observation_map do
    %{
      "repository_root" => "/tmp/kiln-fixture",
      "repository_fingerprint" => @fingerprint,
      "observed_at" => DateTime.to_iso8601(@at)
    }
  end

  # Build a session.start envelope, optionally merging in extra top-level
  # keys (idempotency_key, request_digest) at the envelope layer.
  defp session_start_body(extra) do
    base = %{
      "method" => "session.start",
      "params" => %{
        "objective" => "Correct one bounded defect",
        "criteria" => ["The focused test passes"],
        "actor_id" => "user:local",
        "project_observation" => observation_map()
      }
    }

    Map.merge(base, extra)
  end

  defp stop_registered_store do
    pid = Process.whereis(Kiln.Store.Connection)

    if is_pid(pid) and Process.alive?(pid) do
      try do
        GenServer.stop(pid, :normal, 1_000)
      catch
        :exit, _reason -> :ok
      end
    end

    :ok
  end
end