defmodule Kiln.M12DPatchRpcTest do
  @moduledoc """
  M12-D WP-08 Lane 3: bounded RPC handler tests for `patch.apply`.

  Acceptance properties (per WP08-WP09-PLAN.md):

    P2 — Production intent/observation journaling. A successful
      `patch.apply` against a real temp repo MUST commit an
      `external_operation_intent_recorded/v1` entry BEFORE PatchService
      applies the bytes, and an `external_operation_observed/v1`
      entry AFTER with the terminal state. Verified via
      `Kiln.Journal.Replay.sessions/1` and direct `journal_entries`
      count.

    P2 — unknown-effect observation. A fault that triggers
      `E_MUTATION_UNKNOWN_EFFECT` from PatchService MUST be paired
      with a `state: "unknown"` observation, not `:succeeded`.

    P5 — Code preservation. `Kiln.RPC.Router.dispatch/2` MUST NOT
      flatten the bounded `:E_MUTATION_UNKNOWN_EFFECT` to
      `E_DISPATCH_FAILED`.

    Scope enforcement. `patch.apply` requires `orchestration:operate`;
      `orchestration:read` returns `E_SCOPE_INSUFFICIENT`.

  Pattern mirrors `Kiln.M12DSessionRpcTest` and `Kiln.M12DKilnDaemonTest`:
  bounded scoped tokens are generated at runtime and injected via
  `Application.put_env(:kiln, :scoped_tokens, ...)` with `on_exit`
  restore. The bounded store connection is started in setup and torn
  down in `on_exit`.
  """

  use ExUnit.Case, async: false

  import Plug.Test

  alias Kiln.Domain.Id
  alias Kiln.Journal.Replay
  alias Kiln.M0PatchDecision, as: Decision
  alias Kiln.M0PatchProposal, as: Proposal
  alias Kiln.M0WorkerOutput, as: WorkerOutput
  alias Kiln.{PatchProposal, PatchService, Service, Store, Workflow}
  alias Kiln.RPC.Router

  @now "2026-07-29T13:30:00Z"
  @at ~U[2026-07-29 13:30:00Z]
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    stop_registered_store()

    previous_tokens = Application.get_env(:kiln, :scoped_tokens)

    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))

    Application.put_env(
      :kiln,
      :scoped_tokens,
      %{read_token => "orchestration:read", operate_token => "orchestration:operate"}
    )

    dir = Path.join(System.tmp_dir!(), "kiln-patch-rpc-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "patch_rpc_#{System.unique_integer([:positive])}",
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
  # P2 — intent + observation journaling on a successful patch.apply
  # ----------------------------------------------------------------

  describe "WP-08 P2 — production intent/observation journaling" do
    test "successful patch.apply commits intent + succeeded observation journal entries",
         %{operate_token: token, store: store, dir: tmp_root} do
      # Start a Session so the journal has a run state to attach operations to.
      %{session: session, run: run} = start_session_through_workflow(token)
      repository = Path.join(tmp_root, "repo1")
      File.mkdir_p!(repository)
      File.write!(Path.join(repository, "README.md"), "# Original\n")

      before_digest = sha256_hex("# Original\n")
      after_content = "# Replaced by patch.apply\n"
      after_digest = sha256_hex(after_content)

      proposal = build_proposal(repository, before_digest, after_content, after_digest)
      decision = build_approve_decision(proposal)
      operations_with_bytes = build_ops_with_bytes(before_digest, after_content, after_digest)

      idempotency_key = "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      request_digest = "sha256:" <> String.duplicate("a", 64)
      operation_id = generate_id(:operation)

      body = %{
        "method" => "patch.apply",
        "params" => %{
          "proposal" => Proposal.to_map(proposal),
          "decision" => decision_to_map(decision),
          "operations_with_bytes" => operations_with_bytes,
          "session_id" => session.id,
          "run_id" => run.id,
          "operation_id" => operation_id,
          "subject_id" => proposal.repository,
          "subject_revision" => 0,
          "expected_session_revision" => 0,
          "actor_id" => "kiln:rpc",
          "idempotency_key" => idempotency_key,
          "request_digest" => request_digest
        }
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 200,
             "patch.apply should succeed; got status=#{conn.status} body=#{inspect(conn.resp_body)}"

      decoded = Jason.decode!(conn.resp_body)
      assert is_map(decoded["evidence"]), "expected evidence map in response, got #{inspect(decoded)}"
      assert decoded["evidence"]["effect"] == "EXACT_TARGET_STATE_OBSERVED"

      # P2 acceptance: the journal has BOTH the intent and the observation
      # entry for THIS session. Replay.sessions/1 confirms the session is
      # present, and a direct COUNT against journal_entries confirms
      # exactly 2 entries (intent + succeeded observation) were appended
      # beyond the session_started entry.
      assert [_session_id] = Replay.sessions(store.conn)

      [[entry_count]] =
        Kiln.Store.Connection.query!(
          store.conn,
          "SELECT COUNT(*) FROM journal_entries WHERE session_id = ?1",
          [session.id]
        )

      # session_started (1) + intent (1) + observation (1) = 3
      assert entry_count == 3,
             "expected exactly 3 journal entries (session_started + intent + observation); got #{entry_count}"

      [[intent_count, succeeded_count, unknown_count, failed_count]] =
        Kiln.Store.Connection.query!(
          store.conn,
          """
          SELECT
            SUM(CASE WHEN entry_type = 'external_operation_intent_recorded/v1' THEN 1 ELSE 0 END),
            SUM(CASE WHEN entry_type = 'external_operation_observed/v1' AND json_extract(payload, '$.operation.state') = 'succeeded' THEN 1 ELSE 0 END),
            SUM(CASE WHEN entry_type = 'external_operation_observed/v1' AND json_extract(payload, '$.operation.state') = 'unknown' THEN 1 ELSE 0 END),
            SUM(CASE WHEN entry_type = 'external_operation_observed/v1' AND json_extract(payload, '$.operation.state') = 'failed' THEN 1 ELSE 0 END)
          FROM journal_entries
          WHERE session_id = ?1
          """,
          [session.id]
        )

      assert intent_count == 1, "expected exactly 1 intent entry, got #{intent_count}"
      assert succeeded_count == 1, "expected exactly 1 succeeded observation, got #{succeeded_count}"
      assert unknown_count == 0, "expected 0 unknown observations, got #{unknown_count}"
      assert failed_count == 0, "expected 0 failed observations, got #{failed_count}"

      # File on disk was actually written through the PatchService path.
      assert File.read!(Path.join(repository, "README.md")) == after_content
    end

    test "patch.apply with a path-escape fault commits intent + :unknown observation",
         %{operate_token: token, store: store, dir: tmp_root} do
      %{session: session, run: run} = start_session_through_workflow(token)
      repository = Path.join(tmp_root, "repo_unknown")
      File.mkdir_p!(repository)
      # No README.md — clean state.

      after_content = "X"
      after_digest = sha256_hex(after_content)

      # Use a `..` in the path so `safe_join` raises during mutation —
      # this triggers `E_MUTATION_UNKNOWN_EFFECT` per the bounded
      # partial-effect semantics in patch_service.ex. The PatchProposal
      # build layer would normally reject `..` paths, but the handler
      # trusts the caller's proposal map (the spec's contract is
      # proposal-shaped input; safe_join is the authoritative refuse
      # point at the mutation step).
      bad_path = "subdir/../escape.md"
      proposal_map = %{
        "id" => "pp_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
        "semantic_digest" => "sha256:" <> String.duplicate("c", 64),
        "plan_ref" => %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
        "attempt_ref" => %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("2", 64)},
        "repository" => repository,
        "base_commit" => String.duplicate("a", 40),
        "base_state_digest" => "sha256:" <> String.duplicate("3", 64),
        "operations" => [
          %{
            "op" => "add",
            "path" => bad_path,
            "before_digest" => nil,
            "after_image_digest" => after_digest,
            "mode" => "100644"
          }
        ],
        "patch_digest" => "sha256:" <> String.duplicate("d", 64),
        "metadata" => %{},
        "supersedes_patch_ref" => nil
      }

      proposal = build_proposal_from_map(proposal_map)
      decision = build_approve_decision(proposal)
      ops_with_bytes = [
        %{
          op: :add,
          path: bad_path,
          content: after_content,
          before_digest: nil,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      idempotency_key = "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      request_digest = "sha256:" <> String.duplicate("b", 64)
      operation_id = generate_id(:operation)

      body = %{
        "method" => "patch.apply",
        "params" => %{
          "proposal" => proposal_map,
          "decision" => decision_to_map(decision),
          "operations_with_bytes" => ops_with_bytes,
          "session_id" => session.id,
          "run_id" => run.id,
          "operation_id" => operation_id,
          "subject_id" => repository,
          "subject_revision" => 0,
          "expected_session_revision" => 0,
          "actor_id" => "kiln:rpc",
          "idempotency_key" => idempotency_key,
          "request_digest" => request_digest
        }
      }

      conn =
        conn(:post, "/api/rpc", Jason.encode!(body))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
        |> Service.call(Service.init([]))

      assert conn.status == 400,
             "patch.apply with a path-escape fault should fail closed; got status=#{conn.status}"

      decoded = Jason.decode!(conn.resp_body)
      assert decoded["code"] == "E_MUTATION_UNKNOWN_EFFECT",
             "expected code=E_MUTATION_UNKNOWN_EFFECT, got #{inspect(decoded)}"

      # P2 acceptance: an `unknown` observation was committed (not
      # `succeeded` and not `failed` — the spec classifies mid-mutation
      # raise-or-throw as unknown-effect per ADR-0024).
      [[intent_count, succeeded_count, unknown_count]] =
        Kiln.Store.Connection.query!(
          store.conn,
          """
          SELECT
            SUM(CASE WHEN entry_type = 'external_operation_intent_recorded/v1' THEN 1 ELSE 0 END),
            SUM(CASE WHEN entry_type = 'external_operation_observed/v1' AND json_extract(payload, '$.operation.state') = 'succeeded' THEN 1 ELSE 0 END),
            SUM(CASE WHEN entry_type = 'external_operation_observed/v1' AND json_extract(payload, '$.operation.state') = 'unknown' THEN 1 ELSE 0 END)
          FROM journal_entries
          WHERE session_id = ?1
          """,
          [session.id]
        )

      assert intent_count == 1, "expected exactly 1 intent entry, got #{intent_count}"
      assert succeeded_count == 0, "expected 0 succeeded observations, got #{succeeded_count}"
      assert unknown_count == 1, "expected exactly 1 unknown observation, got #{unknown_count}"
    end
  end

  # ----------------------------------------------------------------
  # P5 — Transport preserves bounded error codes
  # ----------------------------------------------------------------

  describe "WP-08 P5 — bounded error codes pass through unchanged" do
    test "patch.apply handler returns E_MUTATION_UNKNOWN_EFFECT through Router",
         %{operate_token: _token, dir: tmp_root} do
      # Start a session so the journal has a run state to attach the
      # operation to (the intent reducer requires `:ready` run state
      # + no current operation).
      %{session: session, run: run} = start_session_through_workflow(nil)

      repository = Path.join(tmp_root, "repo_p5")
      File.mkdir_p!(repository)
      after_content = "X"
      after_digest = sha256_hex(after_content)

      bad_path = "subdir/../escape.md"
      proposal_map = base_proposal_map(repository, [
        %{
          "op" => "add",
          "path" => bad_path,
          "before_digest" => nil,
          "after_image_digest" => after_digest,
          "mode" => "100644"
        }
      ])

      proposal = build_proposal_from_map(proposal_map)
      decision = build_approve_decision(proposal)
      ops_with_bytes = [
        %{
          op: :add,
          path: bad_path,
          content: after_content,
          before_digest: nil,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      body = %{
        "method" => "patch.apply",
        "params" => %{
          "proposal" => proposal_map,
          "decision" => decision_to_map(decision),
          "operations_with_bytes" => ops_with_bytes,
          "session_id" => session.id,
          "run_id" => run.id,
          "operation_id" => generate_id(:operation),
          "subject_id" => repository,
          "subject_revision" => 0,
          "expected_session_revision" => 0,
          "actor_id" => "kiln:rpc",
          "idempotency_key" => "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower),
          "request_digest" => "sha256:" <> String.duplicate("e", 64)
        }
      }

      # P5 acceptance: the Router preserves the bounded
      # :E_MUTATION_UNKNOWN_EFFECT code (NOT flattened to
      # :E_DISPATCH_FAILED).
      result = Router.dispatch("orchestration:operate", body)

      assert {:error, %{code: :E_MUTATION_UNKNOWN_EFFECT}} = result,
             "expected code=E_MUTATION_UNKNOWN_EFFECT, got #{inspect(result)}"
    end
  end

  # ----------------------------------------------------------------
  # Scope enforcement
  # ----------------------------------------------------------------

  describe "WP-08 Lane 3 — scope enforcement" do
    test "patch.apply with orchestration:read returns E_SCOPE_INSUFFICIENT" do
      body = %{
        "method" => "patch.apply",
        "params" => %{}
      }

      assert {:error, %{code: :E_SCOPE_INSUFFICIENT} = err} =
               Router.dispatch("orchestration:read", body)

      assert err.method == "patch.apply"
    end

    test "patch.apply with orchestration:operate passes scope" do
      body = %{
        "method" => "patch.apply",
        "params" => %{}
      }

      # Scope check passes — the handler will return its own bounded
      # error (e.g. E_MISSING_FIELDS) for an empty params, which is
      # acceptable. The point is: NOT E_SCOPE_INSUFFICIENT.
      result = Router.dispatch("orchestration:operate", body)

      assert {:error, %{code: code}} = result
      refute code == :E_SCOPE_INSUFFICIENT,
             "scope check must pass for patch.apply with orchestration:operate; got #{inspect(result)}"
    end
  end

  # ----------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------

  # Start a Session via the public Workflow API so the journal has a
  # session_started entry. The patch handler's intent reducer requires
  # `ready` run state and no current operation, which is exactly the
  # post-session.start projection.
  defp start_session_through_workflow(_token) do
    po = %{
      repository_root: "/tmp/kiln-fixture",
      repository_fingerprint: @fingerprint,
      observed_at: @at
    }

    {:ok, started} =
      Workflow.start_session(
        actor_id: "user:local",
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: po,
        idempotency_key: "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      )

    # The Workflow.start_session return shape (per workflow.ex:96-104) is
    # %{session_id, task_id, run_id, action_id, session_revision,
    #   run_state, projection_digest}. Surface a session+run-shaped
    # value so the test sites can match on session.id / run.id.
    %{
      session: %{id: started.session_id},
      run: %{id: started.run_id}
    }
  end

  defp build_proposal(repository, before_digest, after_content, after_digest) do
    worker_output = %WorkerOutput{
      id: "wko_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
      semantic_digest: "sha256:" <> String.duplicate("d", 64),
      attempt_ref: %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("e", 64)},
      assignment_ref: %{"id" => "asg_test", "digest" => "sha256:" <> String.duplicate("f", 64)},
      profile_ref: %{"id" => "prf_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      output_kind: "PATCH_CANDIDATE",
      raw_completion_ref: %{
        "id" => "raw_test",
        "digest" => "sha256:" <> String.duplicate("2", 64)
      },
      parsed_candidate_digest: "sha256:" <> String.duplicate("3", 64),
      completion_bytes: "{}",
      base_commit: String.duplicate("a", 40),
      base_state_digest: "sha256:" <> String.duplicate("4", 64),
      adapter_implementation_digest: "sha256:" <> String.duplicate("5", 64)
    }

    operations = [
      %{
        op: :replace,
        path: "README.md",
        content: after_content,
        before_digest: before_digest,
        after_image_digest: after_digest
      }
    ]

    plan_ref = %{
      "id" => "pln_test",
      "digest" => "sha256:" <> String.duplicate("6", 64)
    }

    {:ok, proposal} = PatchProposal.build(worker_output, operations, plan_ref, repository)
    proposal
  end

  defp build_approve_decision(proposal) do
    {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
    decision
  end

  defp build_ops_with_bytes(before_digest, after_content, after_digest) do
    [
      %{
        op: :replace,
        path: "README.md",
        content: after_content,
        before_digest: before_digest,
        after_image_digest: after_digest
      }
    ]
  end

  defp base_proposal_map(repository, operations) do
    %{
      "id" => "pp_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
      "semantic_digest" => "sha256:" <> String.duplicate("c", 64),
      "plan_ref" => %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      "attempt_ref" => %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("2", 64)},
      "repository" => repository,
      "base_commit" => String.duplicate("a", 40),
      "base_state_digest" => "sha256:" <> String.duplicate("3", 64),
      "operations" => operations,
      "patch_digest" => "sha256:" <> String.duplicate("d", 64),
      "metadata" => %{},
      "supersedes_patch_ref" => nil
    }
  end

  # Convert a string-keyed proposal map (JSON-decoded) into a Proposal
  # struct so `PatchService.decide/3` and the handler can both consume
  # it. Mirrors the handler's `coerce_proposal/1` for the test path.
  defp build_proposal_from_map(proposal_map) do
    atomized =
      Enum.reduce(proposal_map, %{}, fn {k, v}, acc ->
        atom_key =
          try do
            String.to_existing_atom(k)
          rescue
            ArgumentError -> nil
          end

        if atom_key, do: Map.put(acc, atom_key, v), else: acc
      end)

    struct(Proposal, atomized)
  end

  defp decision_to_map(%Decision{} = decision) do
    %{
      "id" => decision.id,
      "semantic_digest" => decision.semantic_digest,
      "patch_ref" => decision.patch_ref,
      "base_state_digest" => decision.base_state_digest,
      "decision" => decision.decision,
      "proposal" => Proposal.to_map(decision.proposal)
    }
  end

  defp generate_id(:session), do: elem(Id.generate(:session), 1)
  defp generate_id(:run), do: elem(Id.generate(:run), 1)
  defp generate_id(:operation), do: elem(Id.generate(:operation), 1)

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
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
