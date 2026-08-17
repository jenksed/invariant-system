defmodule Kiln.M11E2ApprovalTransferTest do
  @moduledoc """
  M11 E2 approval-transfer negative property.

  A previous PatchDecision does NOT transfer to a different bounded
  completion — even if the completion is a valid
  `implementer-patch-proposal-input/v1` envelope, even if it would
  rebuild a syntactically valid PatchProposal, even if both proposals
  share the same plan_ref. The governed-apply boundary MUST reject
  the application before any filesystem mutation when the rebuilt
  proposal's canonical semantic identity does not equal the approved
  proposal's canonical semantic identity.

  This is the negative proof of the canonical E2 governed provenance
  property: the exact bytes applied are cryptographically and
  deterministically derived from the immutable governed Worker
  completion that produced the approved PatchProposal. A different
  completion — even one that would rebuild a valid proposal — does
  not carry the original approval.

  Authority doctrine compliance:
  - "A previous approval does not transfer to different bytes or a
    different base state." (governing doctrine)
  - "Implementer cannot authorize its own patch." (governing doctrine)
  - "HumanDecision is never inferred." (governing doctrine)
  """

  use ExUnit.Case, async: false

  alias Kiln.Artifact.Store, as: ArtifactStore
  alias Kiln.Artifact.PutRequest
  alias Kiln.PatchProposal
  alias Kiln.PatchService
  alias Kiln.M0PatchProposal, as: Proposal
  alias Kiln.M0WorkerOutput, as: WorkerOutput
  alias Kiln.Store
  alias Kiln.Store.Uuid

  @now "2026-08-17T12:00:00Z"
  @envelope_schema "engineering-system/implementer-patch-proposal-input/v1"

  defp envelope_with(op) do
    %{
      "schema" => @envelope_schema,
      "operations" => [op]
    }
  end

  defp repo_root(prefix) do
    dir = Path.join(System.tmp_dir!(), "kiln_neg_#{prefix}_#{Uuid.v7()}")
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    dir
  end

  defp start_store(base) do
    state_path = Path.join(base, "state.sqlite3")
    Kiln.Store.start(path: state_path, store_id: "neg_#{Uuid.v7()}", now: @now)
  end

  setup do
    base = Path.join(System.tmp_dir!(), "kiln_neg_state_#{Uuid.v7()}")
    File.rm_rf!(base)
    File.mkdir_p!(base)
    {:ready, store} = start_store(base)
    on_exit(fn ->
      stop(store.conn)
      File.rm_rf!(base)
    end)
    {:ok, store: store, base: base}
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _ -> :ok
  end

  defp approved_proposal(wo, ops_with_bytes, plan_ref, repository) do
    {:ok, proposal} =
      PatchProposal.build_from_worker_output(wo, ops_with_bytes, plan_ref, repository)

    {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
    {proposal, decision}
  end

  test "approved PatchProposal A + WorkerOutput that rebuilds B is rejected before mutation", %{
    store: store,
    base: _base
  } do
    repo = repo_root("approval_transfer")
    File.write!(Path.join(repo, "README.md"), "# Original\n")

    # --- Approved PatchProposal A: replace README.md with "# after-A\n" ---
    envelope_a =
      envelope_with(%{
        "op" => "replace",
        "path" => "README.md",
        "expected_before_digest" =>
          "sha256:" <> Base.encode16(:crypto.hash(:sha256, "# Original\n"), case: :lower),
        "after_image_bytes" => "# after-A\n",
        "mode" => "100644"
      })

    bytes_a = JSON.encode!(envelope_a)
    {:ok, ops_a} = PatchProposal.decode_envelope(bytes_a)
    {:ok, artifact_a, _} =
      ArtifactStore.put(
        store,
        %PutRequest{
          artifact_id: Uuid.v7(),
          idempotency_key: "neg_wo_a:" <> Uuid.v7(),
          recorded_at: @now,
          bytes: bytes_a,
          metadata: %{
            session_id: "neg",
            run_id: "neg",
            owner_kind: :session,
            owner_id: "neg",
            producer_kind: :deterministic_service,
            producer_id: "neg",
            kind: :output,
            media_type: "application/json",
            encoding: :utf_8,
            trust: :kiln_generated,
            sensitivity: :project,
            retention_class: :session,
            completeness: :complete
          }
        }
      )

    {:ok, _status_a, %WorkerOutput{} = wo_a} =
      Kiln.WorkerOutputStore.publish(store, %WorkerOutput{
        id: "wko_a",
        semantic_digest: "sha256:" <> Base.encode16(:crypto.hash(:sha256, bytes_a), case: :lower),
        attempt_ref: %{"id" => "att_a", "digest" => "sha256:" <> String.duplicate("a", 64)},
        assignment_ref: %{"id" => "asg_a", "digest" => "sha256:" <> String.duplicate("b", 64)},
        profile_ref: %{"id" => "prf_a", "digest" => "sha256:" <> String.duplicate("0", 64)},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => artifact_a.artifact_id, "digest" => artifact_a.content_digest},
        parsed_candidate_digest: "sha256:" <> String.duplicate("c", 64),
        completion_bytes: bytes_a,
        base_commit: "deadbeef" <> String.duplicate("0", 32),
        base_state_digest: "sha256:" <> String.duplicate("d", 64),
        adapter_implementation_digest: "sha256:" <> String.duplicate("e", 64)
      })

    plan_ref = %{"id" => "pln_neg", "digest" => "sha256:" <> String.duplicate("0", 64)}
    {proposal_a, decision} = approved_proposal(wo_a, ops_a, plan_ref, repo)

    # Sanity: A rebuilds to the same digest (property of the canonical contract)
    {:ok, ops_a2} = PatchProposal.decode_envelope(bytes_a)
    {:ok, proposal_a2} = PatchProposal.build_from_worker_output(wo_a, ops_a2, plan_ref, repo)
    assert proposal_a2.patch_digest == proposal_a.patch_digest
    assert proposal_a2.semantic_digest == proposal_a.semantic_digest

    # --- WorkerOutput B: a *different* bounded completion that would
    # rebuild PatchProposal B (different operations) ---
    envelope_b =
      envelope_with(%{
        "op" => "add",
        "path" => "OTHER.md",
        "after_image_bytes" => "# other\n",
        "mode" => "100644"
      })

    bytes_b = JSON.encode!(envelope_b)
    {:ok, artifact_b, _} =
      ArtifactStore.put(
        store,
        %PutRequest{
          artifact_id: Uuid.v7(),
          idempotency_key: "neg_wo_b:" <> Uuid.v7(),
          recorded_at: @now,
          bytes: bytes_b,
          metadata: %{
            session_id: "neg",
            run_id: "neg",
            owner_kind: :session,
            owner_id: "neg",
            producer_kind: :deterministic_service,
            producer_id: "neg",
            kind: :output,
            media_type: "application/json",
            encoding: :utf_8,
            trust: :kiln_generated,
            sensitivity: :project,
            retention_class: :session,
            completeness: :complete
          }
        }
      )

    {:ok, _status_b, %WorkerOutput{} = wo_b} =
      Kiln.WorkerOutputStore.publish(store, %WorkerOutput{
        id: "wko_b",
        semantic_digest: "sha256:" <> Base.encode16(:crypto.hash(:sha256, bytes_b), case: :lower),
        attempt_ref: %{"id" => "att_b", "digest" => "sha256:" <> String.duplicate("a", 64)},
        assignment_ref: %{"id" => "asg_b", "digest" => "sha256:" <> String.duplicate("b", 64)},
        profile_ref: %{"id" => "prf_b", "digest" => "sha256:" <> String.duplicate("0", 64)},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => artifact_b.artifact_id, "digest" => artifact_b.content_digest},
        parsed_candidate_digest: "sha256:" <> String.duplicate("c", 64),
        completion_bytes: bytes_b,
        base_commit: "deadbeef" <> String.duplicate("0", 32),
        base_state_digest: "sha256:" <> String.duplicate("d", 64),
        adapter_implementation_digest: "sha256:" <> String.duplicate("e", 64)
      })

    # Canonical: rebuilding B from wo_b yields a proposal whose
    # semantic_digest != proposal_a.semantic_digest (A != B).
    {:ok, ops_b} = PatchProposal.decode_envelope(bytes_b)
    {:ok, proposal_b_from_b} = PatchProposal.build_from_worker_output(wo_b, ops_b, plan_ref, repo)
    assert proposal_b_from_b.semantic_digest != proposal_a.semantic_digest
    assert proposal_b_from_b.patch_digest != proposal_a.patch_digest

    # --- The negative property: patch-apply-governed with approved A
    # but WorkerOutput that rebuilds B MUST reject before any
    # filesystem mutation. No successful PatchApplicationEvidence. ---
    on_disk_before = File.read!(Path.join(repo, "README.md"))
    refute File.exists?(Path.join(repo, "OTHER.md"))

    assert {:error, _reason} =
             PatchService.apply_with_completion_ref(
               proposal_a,
               decision,
               wo_b,
               store
             )

    # Zero unauthorized filesystem effect.
    assert File.read!(Path.join(repo, "README.md")) == on_disk_before,
           "approved base state must remain untouched after a rejected apply"

    refute File.exists?(Path.join(repo, "OTHER.md")),
           "B's bounded content must not have been written to disk"
  end

  test "approved PatchProposal A + repository at state Y (not X) is rejected before mutation", %{
    store: store,
    base: _base
  } do
    repo = repo_root("stale_base")
    File.write!(Path.join(repo, "README.md"), "# Original\n")
    on_disk_before = File.read!(Path.join(repo, "README.md"))

    # --- Approved PatchProposal A: expects preimage "# Original\n" ---
    before_digest =
      "sha256:" <> Base.encode16(:crypto.hash(:sha256, "# Original\n"), case: :lower)

    envelope_a =
      envelope_with(%{
        "op" => "replace",
        "path" => "README.md",
        "expected_before_digest" => before_digest,
        "after_image_bytes" => "# after-A\n",
        "mode" => "100644"
      })

    bytes_a = JSON.encode!(envelope_a)
    {:ok, ops_a} = PatchProposal.decode_envelope(bytes_a)
    {:ok, artifact_a, _} =
      ArtifactStore.put(
        store,
        %PutRequest{
          artifact_id: Uuid.v7(),
          idempotency_key: "neg_stale_a:" <> Uuid.v7(),
          recorded_at: @now,
          bytes: bytes_a,
          metadata: %{
            session_id: "neg",
            run_id: "neg",
            owner_kind: :session,
            owner_id: "neg",
            producer_kind: :deterministic_service,
            producer_id: "neg",
            kind: :output,
            media_type: "application/json",
            encoding: :utf_8,
            trust: :kiln_generated,
            sensitivity: :project,
            retention_class: :session,
            completeness: :complete
          }
        }
      )

    {:ok, _status_a, %WorkerOutput{} = wo_a} =
      Kiln.WorkerOutputStore.publish(store, %WorkerOutput{
        id: "wko_stale_a",
        semantic_digest: "sha256:" <> Base.encode16(:crypto.hash(:sha256, bytes_a), case: :lower),
        attempt_ref: %{"id" => "att_sa", "digest" => "sha256:" <> String.duplicate("a", 64)},
        assignment_ref: %{"id" => "asg_sa", "digest" => "sha256:" <> String.duplicate("b", 64)},
        profile_ref: %{"id" => "prf_sa", "digest" => "sha256:" <> String.duplicate("0", 64)},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => artifact_a.artifact_id, "digest" => artifact_a.content_digest},
        parsed_candidate_digest: "sha256:" <> String.duplicate("c", 64),
        completion_bytes: bytes_a,
        base_commit: "deadbeef" <> String.duplicate("0", 32),
        base_state_digest: "sha256:" <> String.duplicate("d", 64),
        adapter_implementation_digest: "sha256:" <> String.duplicate("e", 64)
      })

    plan_ref = %{"id" => "pln_stale", "digest" => "sha256:" <> String.duplicate("0", 64)}
    {proposal_a, decision} = approved_proposal(wo_a, ops_a, plan_ref, repo)

    # --- Mutate the repository to state Y (not the approved X) ---
    File.write!(Path.join(repo, "README.md"), "# Mutated-to-Y\n")

    # --- patch-apply-governed must reject: approval binds exact
    # content identity AND exact base state. ---
    assert {:error, _reason} =
             PatchService.apply_with_completion_ref(
               proposal_a,
               decision,
               wo_a,
               store
             )

    assert File.read!(Path.join(repo, "README.md")) == "# Mutated-to-Y\n",
           "apply on a stale base state must not have been written"
  end
end
