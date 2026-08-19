defmodule Kiln.M12DHandlersTest do
  @moduledoc """
  WP-09 Lane 1 acceptance tests for the new RPC handlers.

  Mirrors the pattern of `Kiln.M12DSessionRpcTest`: bounded scoped
  tokens generated at runtime (never hardcoded), Store started in
  setup with `on_exit` cleanup, scoped env restored.

  Properties verified:
    * WP-09 Section 6 (reconciliation) — every required method
      dispatches to a real bounded handler.
    * WP-09 Section 7 (contract freeze) — every envelope validates
      required fields, returns bounded :code errors, never
      flattens to E_DISPATCH_FAILED.
    * WP-08 P5 preservation — bounded error codes pass through
      Router.dispatch/2 unchanged.
    * Reviewer independence — `Kiln.Review.build/9` rejects an
      assignment whose digest equals the implementer's digest.
  """

  use ExUnit.Case, async: false

  import Plug.Test

  alias Kiln.{Service, Store}
  alias Kiln.RPC.Router

  @now "2026-08-19T13:30:00Z"
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    stop_registered_store()
    previous_tokens = Application.get_env(:kiln, :scoped_tokens)

    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))
    # review.propose requires `review:write` per the frozen WP-09
    # scope table (LANE-EVIDENCE-WP09-CONTRACTS.md §4). The operate
    # token does NOT grant this scope (exact-match, not superset);
    # therefore review.propose tests must use the dedicated
    # review_write_token below.
    review_write_token = Base.encode16(:crypto.strong_rand_bytes(32))

    Application.put_env(
      :kiln,
      :scoped_tokens,
      %{
        read_token => "orchestration:read",
        operate_token => "orchestration:operate",
        review_write_token => "review:write"
      }
    )

    dir = Path.join(System.tmp_dir!(), "kiln-wp09-handlers-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "wp09_handlers_#{System.unique_integer([:positive])}",
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
      review_write_token: review_write_token,
      store: store
    }
  end

  defp stop_registered_store do
    case Process.whereis(Kiln.Store.Connection) do
      nil ->
        :ok

      pid ->
        # The Store Connection is started via Connection.start_link
        # (Store.start/1 → Connection.start_link/1, store.ex:85). The
        # link goes to whichever process called Store.start/1 — i.e.
        # the test setup. When the test process is exiting, on_exit
        # may run after the test process has already begun shutdown,
        # so a linked GenServer.stop/3 can deliver an EXIT signal into
        # a half-dead test process. Unlink first, then stop.
        Process.unlink(pid)

        if Process.alive?(pid) do
          try do
            GenServer.stop(pid, :normal, 5_000)
          catch
            :exit, _ -> :ok
          end
        end

        :ok
    end
  rescue
    _ -> :ok
  end

  defp post_rpc(token, body) do
    json = Jason.encode!(body)
    conn = conn(:post, "/api/rpc", json) |> Plug.Conn.put_req_header("content-type", "application/json")
    conn = Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
    Service.call(conn, Service.init([]))
  end

  # -- WP-09 Lane 1 — required methods are routed --

  test "router routes worker.propose to Kiln.RPC.Handlers.Worker", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "worker.propose", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert %{"code" => code} = body
    assert code == "E_MISSING_FIELDS"
    assert is_list(body["fields"])
    assert "repository_root" in body["fields"]
  end

  test "router routes verify.run to Kiln.RPC.Handlers.Verify", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "verify.run", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_MISSING_FIELDS"
  end

  test "router routes review.propose to Kiln.RPC.Handlers.Review", %{review_write_token: tok} do
    conn = post_rpc(tok, %{method: "review.propose", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_MISSING_FIELDS"
  end

  test "router routes human.decide to Kiln.RPC.Handlers.HumanDecision", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "human.decide", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_MISSING_FIELDS"
  end

  test "router routes project.open to Kiln.RPC.Handlers.Project", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "project.open", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_MISSING_FIELDS"
  end

  test "router routes project.list to bounded empty list", %{read_token: tok} do
    conn = post_rpc(tok, %{method: "project.list", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert is_map(body)
    assert body["projects"] == []
  end

  # -- contract freeze: bounded error codes preserved (P5) --

  test "patch.apply with stale bytes returns E_PATCH_PREIMAGE_MISMATCH (P3)", %{operate_token: tok} do
    # Establish a real Session via session.start so P2 intent journaling
    # has a session_start anchor in the journal. Without this anchor,
    # the journal reducer rejects the intent entry with :invalid_entry
    # BEFORE PatchService.apply runs, and the P3 property never gets
    # exercised. This fixture exists to prove the property itself.
    fixture = "/tmp/kiln-fixture"
    File.mkdir_p!(fixture)
    File.write!(Path.join(fixture, "EXISTING.md"), "already there\n")

    session_body = %{
      method: "session.start",
      params: %{
        "objective" => "wp-09 stale-patch test",
        "criteria" => ["bounded"],
        "actor_id" => "operator",
        "project_observation" => %{
          "repository_root" => fixture,
          "repository_fingerprint" => @fingerprint,
          "observed_at" => DateTime.to_iso8601(@at)
        }
      }
    }

    start_conn = post_rpc(tok, session_body)
    assert start_conn.status == 200, "session.start failed: #{start_conn.resp_body}"
    started = Jason.decode!(start_conn.resp_body)
    session_id = started["session_id"] || started["Session"]["session_id"]
    assert is_binary(session_id) and byte_size(session_id) > 0

    # Construct a proposal that triggers E_PATCH_PREIMAGE_MISMATCH.
    # An :add op to an existing file at the target path is the canonical
    # P3 stale-preimage condition. The proposal's digest fields must match
    # the decision's digest fields (P3 authority-binding invariant).
    base_state_digest = "sha256:" <> String.duplicate("a", 64)
    patch_digest = "sha256:" <> String.duplicate("b", 64)

    conn =
      post_rpc(tok, %{
        method: "patch.apply",
        params: %{
          "proposal" => %{
            "id" => "pp_stale",
            "patch_digest" => patch_digest,
            "base_state_digest" => base_state_digest,
            "repository" => fixture,
            "operations" => [
              %{
                "op" => "add",
                "path" => "EXISTING.md",
                "bytes" => "would clobber\n"
              }
            ]
          },
          "decision" => %{
            "decision" => "APPROVE_EXACT_BYTES",
            "patch_ref" => %{"id" => "pp_stale", "digest" => patch_digest},
            "base_state_digest" => base_state_digest
          },
          "operations_with_bytes" => [
            %{
              "op" => "add",
              "path" => "EXISTING.md",
              "bytes" => "would clobber\n"
            }
          ],
          "session_id" => session_id,
          "run_id" => "run_" <> String.duplicate("b", 32),
          "operation_id" => "opn_" <> String.duplicate("c", 32),
          "subject_id" => fixture,
          "actor_id" => "operator",
          "idempotency_key" => "idem_" <> String.duplicate("d", 32),
          "request_digest" => "sha256:" <> String.duplicate("0", 64)
        }
      })

    body = Jason.decode!(conn.resp_body)
    # The P3 acceptance property: stale preimage bytes fail closed with
    # E_PATCH_PREIMAGE_MISMATCH. This is the bounded code that proves
    # the property itself — NOT a transport-proxy assertion.
    assert body["code"] == "E_PATCH_PREIMAGE_MISMATCH",
           "expected E_PATCH_PREIMAGE_MISMATCH, got #{inspect(body)}"
  end

  test "router rejects unknown method with E_UNKNOWN_METHOD (no flattening)", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "definitely.not.real", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_UNKNOWN_METHOD"
    assert body["method"] == "definitely.not.real"
  end

  test "router rejects terminal.attach for orchestration:operate token (exact scope)", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "terminal.attach", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_SCOPE_INSUFFICIENT"
    assert body["method"] == "terminal.attach"
  end

  # -- contract freeze §3: bounded error codes list --

  test "envelope-level idempotency_key + request_digest are accepted", %{operate_token: tok} do
    idem = "idem_" <> String.duplicate("a", 32)
    digest = "sha256:" <> String.duplicate("0", 64)

    conn =
      post_rpc(tok, %{
        method: "patch.apply",
        params: %{
          "proposal" => %{"id" => "pp_x"},
          "decision" => %{"decision" => "APPROVE_EXACT_BYTES"},
          "operations_with_bytes" => [],
          "session_id" => "ses_" <> String.duplicate("a", 32),
          "run_id" => "run_" <> String.duplicate("b", 32),
          "operation_id" => "opn_" <> String.duplicate("c", 32),
          "subject_id" => "test",
          "actor_id" => "test"
          # NOTE: no idempotency_key or request_digest in params
        },
        idempotency_key: idem,
        request_digest: digest
      })

    body = Jason.decode!(conn.resp_body)
    # The patch.apply handler should accept envelope-level idem + digest.
    assert body["code"] != "E_DISPATCH_FAILED"
  end

  # -- reviewer independence (M9Review.build/9) --

  test "review.propose with reviewer==implementer digest is rejected", %{review_write_token: tok} do
    common_digest = "sha256:0000000000000000000000000000000000000000000000000000000000000001"
    conn =
      post_rpc(tok, %{
        method: "review.propose",
        params: %{
          "implementer_assignment_ref" => %{"id" => "asg_imp", "digest" => common_digest},
          "plan_ref" => %{"id" => "plan_x", "digest" => common_digest},
          "patch_ref" => %{"id" => "patch_x", "digest" => common_digest},
          "result_state_digest" => common_digest,
          "verification_ref" => %{"id" => "ver_x", "digest" => common_digest},
          "reviewer_assignment_ref" => %{"id" => "asg_rev", "digest" => common_digest},
          "verdict" => "APPROVE",
          "findings" => ["bounded"],
          "context_manifest_ref" => %{"id" => "ctx_x", "digest" => common_digest}
        }
      })

    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_REVIEWER_CONTEXT_CONTAMINATED"
  end

  # -- human decision validation --

  test "human.decide with invalid decision returns E_HUMAN_DECISION_INVALID", %{operate_token: tok} do
    conn =
      post_rpc(tok, %{
        method: "human.decide",
        params: %{
          "plan_ref" => %{"id" => "plan_x", "digest" => "sha256:" <> String.duplicate("0", 64)},
          "patch_ref" => %{"id" => "patch_x", "digest" => "sha256:" <> String.duplicate("0", 64)},
          "result_state_digest" => "sha256:" <> String.duplicate("0", 64),
          "decision" => "DEFinitely_not_valid"
        }
      })

    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_HUMAN_DECISION_INVALID"
  end

  # -- verify.run validation --

  test "verify.run with invalid status returns E_VERIFICATION_STATUS_INVALID", %{operate_token: tok} do
    digest = "sha256:" <> String.duplicate("0", 64)
    conn =
      post_rpc(tok, %{
        method: "verify.run",
        params: %{
          "plan_ref" => %{"id" => "p", "digest" => digest},
          "patch_ref" => %{"id" => "pa", "digest" => digest},
          "result_state_digest" => digest,
          "registered_verifier" => %{"id" => "v", "digest" => digest},
          "status" => "MAYBE",
          "evidence_refs" => [%{"id" => "e", "digest" => digest}]
        }
      })

    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_VERIFICATION_STATUS_INVALID"
  end

  # -- activity.subscribe --

  test "activity.subscribe returns bounded subscription_id + schema_version", %{read_token: tok} do
    sub_id = "sub_" <> String.duplicate("a", 32)
    conn =
      post_rpc(tok, %{
        method: "activity.subscribe",
        params: %{"subscription_id" => sub_id}
      })

    body = Jason.decode!(conn.resp_body)
    assert body["subscription_id"] == sub_id
    assert body["schema_version"] == "kiln/activity/v1"
    assert is_list(body["unknowns"])
    assert is_boolean(body["orphaned"])
  end
end
