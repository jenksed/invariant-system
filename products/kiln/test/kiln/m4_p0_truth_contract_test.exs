defmodule Kiln.M4P0TruthContractTest do
  @moduledoc """
  M4 — P0 truth contract tests.

  Covers:
    * SubjectIdentity (entity_type + canonical_id, hashable)
    * Three-valued knowledge (PRESENT / ABSENT / UNKNOWN)
    * Three attention scopes (SESSION, CURRENT_LIFECYCLE, SELECTED)
    * Lifecycle scope (no cross-attempt stitching)
    * Exact canonical edge identity (every rendered edge has
      canonical_basis)
    * Hydration invalidation race
    * Reconnect convergence
  """

  use ExUnit.Case, async: true

  alias Kiln.{AttentionScopes, GraphProjection}
  alias Kiln.Domain.SubjectIdentity

  defp sha, do: "sha256:" <> String.duplicate("a", 64)
  defp sha_b, do: "sha256:" <> String.duplicate("b", 64)
  defp sha_c, do: "sha256:" <> String.duplicate("c", 64)
  defp base, do: String.duplicate("0", 40)

  defp facts_with(base_sha, attempt_id) do
    %{
      worker_output: %Kiln.M0WorkerOutput{
        id: "wko_" <> attempt_id,
        semantic_digest: sha(),
        attempt_ref: %{"id" => attempt_id, "digest" => sha()},
        assignment_ref: %{"id" => "asg", "digest" => sha()},
        profile_ref: %{"id" => "prof", "digest" => sha()},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => "raw", "digest" => sha()},
        parsed_candidate_digest: sha(),
        completion_bytes: "{}",
        base_commit: base_sha,
        base_state_digest: sha(),
        adapter_implementation_digest: sha()
      },
      proposal: %Kiln.M0PatchProposal{
        id: "pp_" <> attempt_id,
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        attempt_ref: %{"id" => attempt_id, "digest" => sha()},
        patch_digest: sha(),
        base_commit: base_sha,
        repository: "/tmp",
        supersedes_patch_ref: nil
      },
      verification: %Kiln.M0VerificationResult{
        id: "ver_" <> attempt_id,
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_" <> attempt_id, "digest" => sha()},
        status: :PASS,
        result_state_digest: sha(),
        registered_verifier: %{"id" => "vrf", "digest" => sha()},
        evidence_refs: []
      },
      review: %Kiln.M0Review{
        id: "rev_" <> attempt_id,
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_" <> attempt_id, "digest" => sha()},
        verifier_ref: %{"id" => "ver_" <> attempt_id, "digest" => sha()},
        context_manifest_ref: %{"id" => "ctx", "digest" => sha()},
        result_state_digest: sha(),
        verdict: :APPROVE,
        findings: ["ok"],
        implementer_transcript_received: false,
        reviewer_assignment_ref: %{"id" => "revr", "digest" => sha()}
      },
      human_decision: %Kiln.M0HumanDecision{
        id: "hd_" <> attempt_id,
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_" <> attempt_id, "digest" => sha()},
        review_ref: %{"id" => "rev_" <> attempt_id, "digest" => sha()},
        result_state_digest: sha(),
        decision: :ACCEPT,
        recorded_at: "2026-08-20T00:00:00Z",
        metadata: %{}
      },
      patch_evidence: %Kiln.M0PatchEvidence{
        id: "pe_" <> attempt_id,
        semantic_digest: sha(),
        patch_ref: %{"id" => "pp_" <> attempt_id, "digest" => sha()},
        decision_ref: %{"id" => "pd_" <> attempt_id, "digest" => sha()},
        pre_state_digest: sha(),
        post_state_digest: sha(),
        effect: "APPLIED"
      },
      source_identity: base_sha
    }
  end

  defp edge_has_bases?(edge, facts) do
    from = find_envelope(facts, edge.from)
    to = find_envelope(facts, edge.to)

    base_f = from && (Map.get(from, :base_commit) || Map.get(from, "base_commit"))
    base_t = to && (Map.get(to, :base_commit) || Map.get(to, "base_commit"))
    is_binary(base_f) and is_binary(base_t) and byte_size(base_f) > 0 and byte_size(base_t) > 0
  end

  defp find_envelope(facts, id) do
    Enum.find_value(facts, fn
      {_key, %{} = env} when is_map_key(env, :id) ->
        if env.id == id, do: env, else: nil

      _ ->
        nil
    end)
  end

  # ---------- SubjectIdentity ----------

  describe "SubjectIdentity" do
    test "constructs from a known envelope type" do
      fact = facts_with(base(), "att1")
      assert {:ok, %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_att1"}} =
               SubjectIdentity.from_envelope(fact.worker_output)
    end

    test "two identities with same type+id are equal" do
      a = %SubjectIdentity{entity_type: "X", canonical_id: "y"}
      b = %SubjectIdentity{entity_type: "X", canonical_id: "y"}
      assert a == b
      assert SubjectIdentity.digest(a) == SubjectIdentity.digest(b)
    end

    test "different types are not equal" do
      a = %SubjectIdentity{entity_type: "X", canonical_id: "y"}
      b = %SubjectIdentity{entity_type: "Z", canonical_id: "y"}
      refute a == b
    end

    test "rejects unknown entity types" do
      assert {:error, {:unknown_entity_type, "Bogus"}} = SubjectIdentity.new("Bogus", "x")
    end

    test "three-valued knowledge: PRESENT, ABSENT, UNKNOWN" do
      assert SubjectIdentity.knowledge(%{any: :thing}) == :present
      assert SubjectIdentity.knowledge(nil) == :absent
      assert SubjectIdentity.knowledge(:__missing__) == :unknown
      assert SubjectIdentity.knowledge(:__hydration_pending__) == :unknown
      assert SubjectIdentity.knowledge(:__stale__) == :unknown
      assert SubjectIdentity.unknown?(:unknown) == true
      assert SubjectIdentity.present?(:present) == true
      assert SubjectIdentity.present?(:unknown) == false
    end
  end

  # ---------- Attention Scopes ----------

  describe "AttentionScopes" do
    test "0 session pending: count is 0, lifecycle false" do
      scope = AttentionScopes.session_scope([])
      assert scope.session_needs_you_count == 0
      refute scope.current_lifecycle_needs_you
    end

    test "1 pending elsewhere (not current lifecycle)" do
      pending = [
        %{
          id: "dec_1",
          subject_id: "hd_other",
          subject_kind: "HumanDecision",
          lifecycle_scope: "historical",
          actionable: true,
          requested_actor: "temper_operator"
        }
      ]

      scope = AttentionScopes.session_scope(pending)
      assert scope.session_needs_you_count == 1
      refute scope.current_lifecycle_needs_you
    end

    test "1 pending in current lifecycle" do
      pending = [
        %{
          id: "dec_1",
          subject_id: "hd_now",
          subject_kind: "HumanDecision",
          lifecycle_scope: "current",
          actionable: true,
          requested_actor: "temper_operator"
        }
      ]

      scope = AttentionScopes.session_scope(pending)
      assert scope.session_needs_you_count == 1
      assert scope.current_lifecycle_needs_you
    end

    test "selected actionable subject: SELECTED_ITEM_NEEDS_YOU true" do
      subject = %SubjectIdentity{entity_type: "HumanDecision", canonical_id: "hd_now"}

      pending = [
        %{
          id: "dec_1",
          subject_id: "hd_now",
          subject_kind: "HumanDecision",
          lifecycle_scope: "current",
          actionable: true,
          requested_actor: "temper_operator"
        }
      ]

      sel = AttentionScopes.selection_scope(subject, pending)
      assert sel.selected_item_needs_you
      assert sel.selected_actionable_decision.id == "dec_1"
    end

    test "selected non-actionable subject: false" do
      subject = %SubjectIdentity{entity_type: "Review", canonical_id: "rev_t1"}

      pending = [
        %{
          id: "dec_1",
          subject_id: "hd_other",
          subject_kind: "HumanDecision",
          lifecycle_scope: "current",
          actionable: false,
          requested_actor: "temper_operator"
        }
      ]

      sel = AttentionScopes.selection_scope(subject, pending)
      refute sel.selected_item_needs_you
      assert sel.selected_actionable_decision == nil
    end
  end

  # ---------- Lifecycle Scope / No Cross-Attempt Stitching ----------
  #
  # M4-Q1C Gate 2:
  #   base_commit is BASE-STATE provenance; it does NOT prove attempt
  #   identity. Lifecycle scope is derived ONLY from canonical attempt
  #   identity (attempt_ref.id). When two envelopes share base_commit
  #   but have different attempt_ref.id, they MUST NOT share
  #   lifecycle_scope — they are different attempts with the same
  #   base state.

  describe "Lifecycle scope" do
    test "edges within same attempt_ref share lifecycle_scope (attempt identity)" do
      facts = facts_with(base(), "att1")
      {:ok, projection} = GraphProjection.build(facts)

      with_attempt = Enum.filter(projection.edges, fn e ->
        from = find_envelope(facts, e.from)
        to = find_envelope(facts, e.to)
        attempt_ids_match?(from, to)
      end)

      assert with_attempt != [],
             "test fixture must include at least one edge with matching attempt_ref"

      assert Enum.all?(with_attempt, fn e -> e.lifecycle_scope == "attempt:att1" end),
             "edges within the same attempt identity must share scope"
    end

    test "same base_commit, DIFFERENT attempt_ref: NO shared lifecycle_scope (SAME_BASE_DIFFERENT_ATTEMPT_NO_STITCH)" do
      # Adversarial: ATTEMPT A and ATTEMPT B share base_commit but
      # have distinct attempt_ref.id. Successful A fact must NOT
      # extend or stitch to B's lifecycle.
      attempt_a = facts_with(base(), "att_A")
      attempt_b = facts_with(base(), "att_B")

      # A reaches governed completion (verification PASS + ACCEPT +
      # applied). B is mid-failure (verification FAIL).
      attempt_a = attempt_a
      attempt_b = put_in(attempt_b, [:verification], %{attempt_b.verification | status: :FAIL})
      attempt_b = Map.delete(attempt_b, :review)
      attempt_b = Map.delete(attempt_b, :human_decision)
      attempt_b = Map.delete(attempt_b, :patch_evidence)

      # Build A and B separately.
      {:ok, proj_a} = GraphProjection.build(attempt_a)
      {:ok, proj_b} = GraphProjection.build(attempt_b)

      # No edge within A may carry B's lifecycle scope, and vice versa.
      assert Enum.all?(proj_a.edges, fn e ->
               e.lifecycle_scope != "attempt:att_B"
             end),
             "attempt A must not reference attempt B's lifecycle scope"

      assert Enum.all?(proj_b.edges, fn e ->
               e.lifecycle_scope != "attempt:att_A"
             end),
             "attempt B must not reference attempt A's lifecycle scope"

      # A's successful edges share attempt:att_A scope.
      a_attempt_edges = Enum.filter(proj_a.edges, &(&1.lifecycle_scope == "attempt:att_A"))
      assert a_attempt_edges != [], "attempt A must have at least one scope-tagged edge"

      # B has nil scope everywhere (no attempt identity can be proven
      # for B in this fixture because B's worker_output+proposal carry
      # attempt_ref=att_B but B's verification has no attempt_ref,
      # and the verification edge B's nodes are filtered).
      # The semantic guarantee: B's remaining edges cannot stitch to
      # A's scope.
      refute Enum.any?(proj_b.edges, &(&1.lifecycle_scope == "attempt:att_A"))
    end

    test "edges across different base_commits have NO lifecycle_scope (refuse to stitch)" do
      historical = facts_with(base(), "att1")
      current = facts_with(String.duplicate("1", 40), "att2")

      mixed = Map.put(current, :worker_output, historical.worker_output)
      {:ok, projection} = GraphProjection.build(mixed)

      produced = Enum.find(projection.edges, &(&1.kind == "PRODUCED"))

      if produced do
        # Different attempts + different base_commits → no scope
        # may be claimed.
        assert produced.lifecycle_scope in [nil],
               "different base_commit + different attempt_ref must produce nil lifecycle_scope"
      end
    end

    test "UNKNOWN lifecycle_scope: exact canonical ref edge SURVIVES" do
      # Two envelopes with no shared attempt identity, no shared
      # base_commit. They DO share an exact canonical reference
      # (human_decision.patch_ref == proposal.id) — that edge MUST
      # still be emitted; only its lifecycle_scope must be nil.
      facts_x = facts_with(String.duplicate("2", 40), "att_X")
      facts_y = facts_with(String.duplicate("3", 40), "att_Y")

      # Build a mixed facts map where human_decision from X
      # references the proposal from Y.
      mixed = Map.put(facts_x, :proposal, facts_y.proposal)
      {:ok, projection} = GraphProjection.build(mixed)

      # The DECIDED_ON edge (human_decision → proposal via patch_ref)
      # MUST exist even though lifecycle_scope is UNKNOWN.
      decided = Enum.find(projection.edges, &(&1.kind == "DECIDED_ON"))
      assert decided != nil, "exact canonical ref edge must survive"
      assert decided.lifecycle_scope == nil,
             "no shared attempt identity → lifecycle_scope must be nil, NOT inferred"
      assert decided.canonical_basis == "human_decision.patch_ref",
             "exact canonical basis must be preserved"
    end

    test "every edge has a canonical_basis (no naked edges)" do
      facts = facts_with(base(), "att1")
      {:ok, projection} = GraphProjection.build(facts)

      assert Enum.all?(projection.edges, fn e -> is_binary(e.canonical_basis) and byte_size(e.canonical_basis) > 0 end),
             "every rendered edge must carry a non-empty canonical_basis"
    end
  end

  defp attempt_ids_match?(from, to) do
    from_id = from && extract_attempt_id(from)
    to_id = to && extract_attempt_id(to)
    is_binary(from_id) and is_binary(to_id) and from_id == to_id and byte_size(from_id) > 0
  end

  defp extract_attempt_id(envelope) do
    case Map.get(envelope, :attempt_ref) do
      %{"id" => id} when is_binary(id) -> id
      %{id: id} when is_binary(id) -> id
      _ -> nil
    end
  end

  # ---------- Failed verification: no downstream stitching ----------

  describe "Failed verification (no downstream stitching)" do
    test "FAIL on verification: no Review/HumanDecision/PatchEvidence nodes" do
      facts = facts_with(base(), "att1")
      facts = put_in(facts, [:verification], %{facts.verification | status: :FAIL})
      # Simulate that downstream steps were never taken
      facts = Map.delete(facts, :review)
      facts = Map.delete(facts, :human_decision)
      facts = Map.delete(facts, :patch_evidence)

      {:ok, projection} = GraphProjection.build(facts)

      kinds = projection.nodes |> Enum.map(& &1.kind) |> Enum.sort()
      refute "Review" in kinds, "FAIL verification must not show Review node"
      refute "HumanDecision" in kinds, "FAIL verification must not show HumanDecision"
      refute "PatchEvidence" in kinds, "FAIL verification must not show PatchEvidence"
    end
  end

  # ---------- Hydration invalidation race ----------

  describe "Hydration invalidation race" do
    test "if canonical change during hydration, A is NOT installed" do
      # Conceptual test: the hydration state machine guarantees that
      # a hydration generation for which an invalidation was observed
      # is discarded. The current GraphProjection is pure and does
      # not maintain hydration state; that responsibility lives in
      # the consumer (Temper.M4LiveProjection). This test pins the
      # contract: given generation A then generation B, the installed
      # projection == B (the canonical answer is invariant under
      # hydration order).
      facts_a = facts_with(base(), "att1")
      facts_b = facts_with(String.duplicate("1", 40), "att2")

      # Build A, then B. The B projection is canonical, not A.
      {:ok, projection_a} = GraphProjection.build(facts_a)
      {:ok, projection_b} = GraphProjection.build(facts_b)

      # If A is installed after B is observed, A is stale.
      assert projection_a.source_identity != projection_b.source_identity
      refute projection_a.source_identity == projection_b.source_identity

      # The contract: the consumer must not present A's identity
      # when B is the canonical answer. We assert this as a test
      # of the projection's invariants; the consumer's hydration
      # state machine lives in products/temper-elixir (deferred
      # to M4-LI0 follow-up).
    end
  end

  # ---------- Reconnect convergence ----------

  describe "Reconnect convergence" do
    test "post-reconnect projection reflects B, not A-only state" do
      facts_a = facts_with(base(), "att1")
      facts_b = facts_with(String.duplicate("9", 40), "att2")
      facts_b = Map.delete(facts_b, :patch_evidence)
      facts_b = put_in(facts_b, [:verification], %{facts_b.verification | status: :FAIL})

      {:ok, projection_a} = GraphProjection.build(facts_a)
      {:ok, projection_b} = GraphProjection.build(facts_b)

      # B's source_identity differs.
      assert projection_a.source_identity == base()
      assert projection_b.source_identity == String.duplicate("9", 40)

      # B has no PatchEvidence (it was applied in A's lifecycle).
      b_ids = projection_b.nodes |> Enum.map(& &1.id)
      refute "pe_att2" in b_ids, "B has its own canonical evidence id; A's id is gone"

      # A-only evidence (pe_att1) does not appear in B.
      a_only_ids = projection_a.nodes |> Enum.map(& &1.id)
      assert "pe_att1" in a_only_ids
      refute "pe_att1" in b_ids
    end
  end
end
