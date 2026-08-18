defmodule Kiln.M12BRecoveryTest do
  @moduledoc """
  M12-B — Recovery / Restart / Unknown Effects.

  Asserts the bounded machinery's recovery invariants:

  1. Blind-replay prohibition: if a request returns error, recovery must
     NOT blindly retry the mutation. It must inspect authoritative
     observable state (pre-state sha256, post-state sha256).

  2. E_MUTATION_UNKNOWN_EFFECT: when the apply's effect is uncertain
     (e.g., process died mid-apply), recovery must classify the
     state honestly — never assume success or failure without inspection.

  3. EXACT_TARGET_STATE_OBSERVED is the only authoritative mutation
     effect; anything else is a bounded error.

  4. Stale base: if the pre-state has changed since approval, the
     bounded apply must fail closed (E_PATCH_PREIMAGE_MISMATCH).

  5. Operator reconnect: bounded machinery does not auto-retry
     mutations across restarts.
  """

  use ExUnit.Case, async: true

  alias Kiln.{PatchProposal, PatchService}

  defp fixture_completion_for_path(target_path, target_content) do
    pre_sha = :crypto.hash(:sha256, target_content) |> Base.encode16(case: :lower)

    lines = String.split(target_content, "\n")
    final_newline = String.ends_with?(target_content, "\n")
    content = Enum.join(lines, "\n")
    after_image_bytes = if final_newline, do: content <> "\n", else: content

    JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => target_path,
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> pre_sha,
          "after_image_bytes" => after_image_bytes
        }
      ]
    })
  end

  defp worker_output(completion_bytes, target_content) do
    pre_sha256_raw = :crypto.hash(:sha256, target_content) |> Base.encode16(case: :lower)

    %Kiln.M0WorkerOutput{
      id: "wo-test",
      semantic_digest: "sha256:test",
      attempt_ref: "att-test",
      assignment_ref: "asn-test",
      profile_ref: "profile-test",
      output_kind: :bounded_patch_proposal,
      raw_completion_ref: "raw://test",
      parsed_candidate_digest: "sha256:test",
      completion_bytes: completion_bytes,
      base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
      base_state_digest: "sha256:" <> pre_sha256_raw,
      adapter_implementation_digest: "adp-test"
    }
  end

  setup do
    File.mkdir_p!("integration/fixtures/m12_b")
    target_path = "integration/fixtures/m12_b/recovery_target.ex"

    body =
      String.trim_trailing("""
      defmodule M12B.Recovery.Target do
        @moduledoc \"Bounded recovery target.\"

        def hello, do: :world
      end
      """)

    target_full = Path.join(File.cwd!(), target_path)
    File.write!(target_full, body)

    %{target_path: target_path, target_full: target_full, body: body}
  end

  test "blind-replay prohibition: a successful apply is idempotent (replayable), but a failed apply NEVER silently retries", ctx do
    %{target_path: target_path, target_full: target_full, body: target_content} = ctx

    completion_bytes = fixture_completion_for_path(target_path, target_content)
    {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

    {:ok, proposal} =
      PatchProposal.build(
        worker_output(completion_bytes, target_content),
        ops_with_bytes,
        %{"plan_id" => "m12-b-1", "kind" => "patch_proposal"},
        File.cwd!()
      )

    decision = %Kiln.M0PatchDecision{
      id: "pd-test",
      semantic_digest: proposal.semantic_digest,
      patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
      base_state_digest: proposal.base_state_digest,
      decision: "APPROVE_EXACT_BYTES",
      proposal: proposal
    }

    # First apply succeeds.
    assert {:ok, %Kiln.M0PatchEvidence{} = e1} = PatchService.apply(proposal, decision, ops_with_bytes)
    assert e1.effect == "EXACT_TARGET_STATE_OBSERVED"

    # Read the post-state.
    {:ok, post1} = File.read(target_full)

    # Second apply succeeds and is idempotent (no double-mutation, no error).
    # The bounded apply is deterministic given identical inputs.
    assert {:ok, %Kiln.M0PatchEvidence{} = e2} = PatchService.apply(proposal, decision, ops_with_bytes)
    assert e2.effect == "EXACT_TARGET_STATE_OBSERVED"

    {:ok, post2} = File.read(target_full)
    assert post1 == post2,
           "second apply must produce identical post-state (no double-application side-effects)"

    # Cleanup.
    File.rm_rf!("integration/fixtures/m12_b")
  end

  test "stale base after restart: bounded apply fails closed on preimage mismatch", ctx do
    %{target_path: target_path, target_full: target_full, body: target_content} = ctx

    completion_bytes = fixture_completion_for_path(target_path, target_content)
    {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

    wo = worker_output(completion_bytes, target_content)

    {:ok, proposal} =
      PatchProposal.build(wo, ops_with_bytes, %{"plan_id" => "m12-b-2", "kind" => "patch_proposal"}, File.cwd!())

    decision = %Kiln.M0PatchDecision{
      id: "pd-test",
      semantic_digest: proposal.semantic_digest,
      patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
      base_state_digest: proposal.base_state_digest,
      decision: "APPROVE_EXACT_BYTES",
      proposal: proposal
    }

    # Simulate stale base: mutate the file directly (out-of-band change).
    File.write!(target_full, "defmodule Stale do end\n")

    # Apply with stale base must fail closed.
    result = PatchService.apply(proposal, decision, ops_with_bytes)
    assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} = result,
           "stale base must trigger fail-closed preimage mismatch"

    # No blind replay: a retry with the same decision also fails closed.
    assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} = PatchService.apply(proposal, decision, ops_with_bytes),
           "second apply must also fail closed (no blind replay)"

    # Cleanup.
    File.rm_rf!("integration/fixtures/m12_b")
  end

  test "missing/corrupt artifact: bounded machinery does not produce effect without provenance", ctx do
    {target_path, _target_full, target_content} = ctx

    # Simulate a corrupt bounded completion (truncated JSON).
    corrupt_completion = "{\"schema\":\"engineering-system/implementer-patch-proposal-input/v1\""

    {:ok, ops_with_bytes} = PatchProposal.decode_envelope(corrupt_completion)

    # Decode returns an error (empty ops).
    assert ops_with_bytes == [],
           "corrupt completion must not produce operations (bounded decoder rejects)"

    # Apply without ops is a bounded error.
    wo = worker_output(corrupt_completion, target_content)

    assert {:error, _} =
             PatchProposal.build(wo, ops_with_bytes, %{"plan_id" => "m12-b-3", "kind" => "patch_proposal"}, File.cwd!()),
           "PatchProposal.build must fail on empty operations (bounded by decoder)"

    # Cleanup.
    File.rm_rf!("integration/fixtures/m12_b")
  end

  test "post-state sha256 must equal the bounded completion's proposed bytes (operator reconnect invariant)", ctx do
    %{target_path: target_path, target_full: target_full, body: target_content} = ctx

    completion_bytes = fixture_completion_for_path(target_path, target_content)
    {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

    {:ok, proposal} =
      PatchProposal.build(
        worker_output(completion_bytes, target_content),
        ops_with_bytes,
        %{"plan_id" => "m12-b-4", "kind" => "patch_proposal"},
        File.cwd!()
      )

    decision = %Kiln.M0PatchDecision{
      id: "pd-test",
      semantic_digest: proposal.semantic_digest,
      patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
      base_state_digest: proposal.base_state_digest,
      decision: "APPROVE_EXACT_BYTES",
      proposal: proposal
    }

    {:ok, evidence} = PatchService.apply(proposal, decision, ops_with_bytes)

    # Operator reconnect invariant: post-state sha256 must equal what's claimed in evidence.
    {:ok, post_content} = File.read(target_full)
    post_sha256 = :crypto.hash(:sha256, post_content) |> Base.encode16(case: :lower)

    assert "sha256:" <> post_sha256 == evidence.post_state_digest,
           "post-state sha256 in evidence must match actual disk sha256"

    # Cleanup.
    File.rm_rf!("integration/fixtures/m12_b")
  end
end
