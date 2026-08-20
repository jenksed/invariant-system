defmodule Kiln.GraphProjection do
  @moduledoc """
  M4-A — TRUTHFUL GRAPH (headless canonical projection).

  Renderer-independent representation of governed work as a graph.
  Consumes the canonical M3 envelope structs and emits a graph with
  nodes (one per canonical entity) and edges (canonical relationships
  between entities).

  Invariants:
    * Every node is bound to a canonical identity (id + digest of
      the underlying envelope).
    * Every edge connects two canonical nodes.
    * Proposed relationships (planner outputs) cannot masquerade as
      governed relationships — the projection distinguishes them.
    * Attention state is a first-class node attribute, NOT a separate
      side-channel.

  Architecture: Kiln.M4 (M4-A, lane M4).
  """

  alias Kiln.{M0HumanDecision, M0PatchEvidence, M0PatchProposal, M0Review,
             M0RunResultProjection, M0VerificationResult, M0WorkerOutput}

  @attention_states ~w(WORKING BLOCKED FAILED WAITING_FOR_HUMAN COMPLETE)

  @type node_id :: String.t()
  @type edge_kind :: String.t()
  @type attention :: String.t()

  @type graph_node :: %{
          required(:id) => node_id(),
          required(:kind) => String.t(),
          required(:label) => String.t(),
          required(:canonical_digest) => String.t(),
          required(:attention) => attention(),
          required(:proposed) => boolean(),
          required(:lifecycle_scope) => String.t() | nil,
          required(:metadata) => map()
        }

  @type graph_edge :: %{
          required(:id) => String.t(),
          required(:kind) => edge_kind(),
          required(:from) => node_id(),
          required(:to) => node_id(),
          required(:direction) => :forward | :backward,
          required(:lifecycle_scope) => String.t() | nil,
          required(:canonical_basis) => String.t(),
          required(:proposed) => boolean()
        }

  @type projection :: %{
          required(:revision) => non_neg_integer(),
          required(:source_identity) => String.t(),
          required(:nodes) => [graph_node()],
          required(:edges) => [graph_edge()]
        }

  @doc "Attention states the projection can label a node with."
  @spec attention_states() :: [String.t()]
  def attention_states, do: @attention_states

  @doc """
  Build a canonical graph projection from a bounded set of M3 envelopes.

  The `facts` map carries the envelopes that exist for one governed
  work unit. Missing envelopes are tolerated — the projection simply
  omits the corresponding nodes and edges.

  Required keys (any may be absent):

    * `:worker_output`     — %M0WorkerOutput{}
    * `:proposal`          — %M0PatchProposal{}
    * `:verification`      — %M0VerificationResult{}
    * `:review`            — %M0Review{}
    * `:human_decision`    — %M0HumanDecision{}
    * `:patch_evidence`    — %M0PatchEvidence{}
    * `:run_state`         — atom() (e.g., :running, :waiting_for_user,
                                :ready, :blocked, :failed)
    * `:source_identity`   — String.t() (e.g., commit SHA of the
                                repository at observation time)

  The projection's `revision` is 1 (monotonic for a given set of
  facts; callers compose by re-projecting as facts change).
  """
  @spec build(map()) :: {:ok, projection()} | {:error, term()}
  def build(facts) when is_map(facts) do
    nodes = build_nodes(facts)
    edges = build_edges(facts, nodes)
    source_identity = Map.get(facts, :source_identity, "unknown")

    {:ok,
     %{
       revision: 1,
       source_identity: source_identity,
       nodes: nodes,
       edges: edges
     }}
  end

  @doc """
  Walk backward from a node, returning the upstream nodes/edges that
  justify it. Used to expose provenance.

  For example, starting at a PatchEvidence node, this returns the
  edges that connect to PatchProposal → HumanDecision → Review →
  VerificationResult → WorkerOutput, plus the human-readable
  reasoning for why each step is part of the chain.
  """
  @spec provenance_for(projection(), node_id()) :: {:ok, [graph_edge()]} | {:error, :unknown_node}
  def provenance_for(projection, node_id) when is_map(projection) and is_binary(node_id) do
    if Enum.any?(projection.nodes, &(&1.id == node_id)) do
      {:ok,
       Enum.filter(projection.edges, fn edge ->
         edge.to == node_id or edge.from == node_id
       end)}
    else
      {:error, :unknown_node}
    end
  end

  @doc """
  Return all nodes that currently require human attention.

  The attention model:
    * WORKING          — active operation in progress
    * BLOCKED          — operation cannot proceed without external input
    * FAILED           — bounded failure (verifier FAIL, review REJECT)
    * WAITING_FOR_HUMAN — canonical run_state == :waiting_for_user
    * COMPLETE         — bounded completion recorded
  """
  @spec attention_required(projection()) :: [graph_node()]
  def attention_required(projection) when is_map(projection) do
    Enum.filter(projection.nodes, fn node ->
      node.attention in ["BLOCKED", "FAILED", "WAITING_FOR_HUMAN"]
    end)
  end

  # --- private ---

  defp build_nodes(facts) do
    []
    |> maybe_add_worker_output(facts)
    |> maybe_add_proposal(facts)
    |> maybe_add_verification(facts)
    |> maybe_add_review(facts)
    |> maybe_add_human_decision(facts)
    |> maybe_add_patch_evidence(facts)
  end

  defp maybe_add_worker_output(nodes, %{worker_output: wo}) when not is_nil(wo) do
    [worker_output_node(wo) | nodes]
  end

  defp maybe_add_worker_output(nodes, _), do: nodes

  defp maybe_add_proposal(nodes, %{proposal: pp}) when not is_nil(pp) do
    [proposal_node(pp) | nodes]
  end

  defp maybe_add_proposal(nodes, _), do: nodes

  defp maybe_add_verification(nodes, %{verification: vr}) when not is_nil(vr) do
    [verification_node(vr) | nodes]
  end

  defp maybe_add_verification(nodes, _), do: nodes

  defp maybe_add_review(nodes, %{review: r}) when not is_nil(r) do
    [review_node(r) | nodes]
  end

  defp maybe_add_review(nodes, _), do: nodes

  defp maybe_add_human_decision(nodes, %{human_decision: hd}) when not is_nil(hd) do
    [human_decision_node(hd) | nodes]
  end

  defp maybe_add_human_decision(nodes, _), do: nodes

  defp maybe_add_patch_evidence(nodes, %{patch_evidence: pe}) when not is_nil(pe) do
    [patch_evidence_node(pe) | nodes]
  end

  defp maybe_add_patch_evidence(nodes, _), do: nodes

  defp build_edges(facts, nodes) do
    node_ids = MapSet.new(nodes, & &1.id)

    []
    |> maybe_add_edge(facts, :worker_output, :proposal, "PRODUCED", node_ids)
    |> maybe_add_edge(facts, :verification, :proposal, "VERIFIED", node_ids)
    |> maybe_add_edge(facts, :review, :proposal, "REVIEWED", node_ids)
    |> maybe_add_edge(facts, :review, :verification, "ASSESSED", node_ids)
    |> maybe_add_edge(facts, :human_decision, :proposal, "DECIDED_ON", node_ids)
    |> maybe_add_edge(facts, :human_decision, :review, "AUTHORIZED", node_ids)
    |> maybe_add_edge(facts, :patch_evidence, :human_decision, "APPLIED_AFTER", node_ids)
    |> maybe_add_edge(facts, :patch_evidence, :proposal, "APPLIED", node_ids)
  end

  defp maybe_add_edge(edges, facts, from_key, to_key, kind, node_ids) do
    from = Map.get(facts, from_key)
    to = Map.get(facts, to_key)

    cond do
      is_nil(from) or is_nil(to) ->
        edges

      not MapSet.member?(node_ids, node_id_of(from)) ->
        edges

      not MapSet.member?(node_ids, node_id_of(to)) ->
        edges

      true ->
        scope = lifecycle_scope(from, to)
        basis = canonical_basis(kind)

        edge = %{
          id: "edg_#{kind}_#{node_id_of(from)}_#{node_id_of(to)}",
          kind: kind,
          from: node_id_of(from),
          to: node_id_of(to),
          direction: :forward,
          lifecycle_scope: scope,
          canonical_basis: basis,
          proposed: false
        }

        [edge | edges]
    end
  end

  defp lifecycle_scope(from, to) do
    # Lifecycle scope is derivable when both endpoints share a
    # base_commit OR share an attempt_ref.id. The scope identifier
    # is the shared base_commit when present, else the shared
    # attempt_ref id. Nil when no lineage can be proven.
    base_from = Map.get(from, :base_commit) || Map.get(from, "base_commit")
    base_to = Map.get(to, :base_commit) || Map.get(to, "base_commit")

    cond do
      is_binary(base_from) and is_binary(base_to) and base_from == base_to and byte_size(base_from) > 0 ->
        "base:" <> base_from

      attemp_refs_match?(from, to) ->
        "attempt:" <> (get_attempt_id(from) || "unknown")

      true ->
        nil
    end
  end

  defp attemp_refs_match?(from, to) do
    from_id = get_attempt_id(from)
    to_id = get_attempt_id(to)

    is_binary(from_id) and is_binary(to_id) and from_id == to_id and byte_size(from_id) > 0
  end

  defp get_attempt_id(envelope) do
    attempt_ref = Map.get(envelope, :attempt_ref) || Map.get(envelope, "attempt_ref")

    case attempt_ref do
      %{"id" => id} when is_binary(id) -> id
      %{id: id} when is_binary(id) -> id
      _ -> nil
    end
  end

  defp canonical_basis("VERIFIED"), do: "verification_result.patch_ref"
  defp canonical_basis("REVIEWED"), do: "review.patch_ref"
  defp canonical_basis("ASSESSED"), do: "review.verifier_ref"
  defp canonical_basis("DECIDED_ON"), do: "human_decision.patch_ref"
  defp canonical_basis("AUTHORIZED"), do: "human_decision.review_ref"
  defp canonical_basis("APPLIED"), do: "patch_evidence.patch_ref"
  defp canonical_basis("APPLIED_AFTER"), do: "patch_evidence.decision_ref"
  defp canonical_basis("PRODUCED"), do: "patch_proposal.build/4(worker_output, ...)"
  defp canonical_basis(other), do: other

  defp node_id_of(%{id: id}), do: id
  defp node_id_of(%{"id" => id}), do: id

  # --- node builders ---

  defp worker_output_node(%M0WorkerOutput{} = wo) do
    %{
      id: wo.id,
      kind: "WorkerOutput",
      label: "Worker Output",
      canonical_digest: wo.semantic_digest,
      attention: "WORKING",
      proposed: false,
      lifecycle_scope: lifecycle_scope_from_base(wo.base_commit),
      metadata: %{
        attempt_ref: wo.attempt_ref,
        base_commit: wo.base_commit
      }
    }
  end

  defp proposal_node(%M0PatchProposal{} = pp) do
    %{
      id: pp.id,
      kind: "PatchProposal",
      label: "Patch Proposal",
      canonical_digest: pp.patch_digest,
      attention: attention_for_proposal(pp),
      proposed: false,
      lifecycle_scope: lifecycle_scope_from_base(pp.base_commit),
      metadata: %{
        plan_ref: pp.plan_ref,
        repository: pp.repository
      }
    }
  end

  defp verification_node(%M0VerificationResult{} = vr) do
    %{
      id: vr.id,
      kind: "VerificationResult",
      label: "Verification: #{vr.status}",
      canonical_digest: vr.semantic_digest,
      attention: attention_for_verification(vr),
      proposed: false,
      lifecycle_scope: nil,
      metadata: %{
        result_state_digest: vr.result_state_digest,
        status: vr.status
      }
    }
  end

  defp review_node(%M0Review{} = r) do
    %{
      id: r.id,
      kind: "Review",
      label: "Review: #{r.verdict}",
      canonical_digest: r.semantic_digest,
      attention: attention_for_review(r),
      proposed: false,
      lifecycle_scope: nil,
      metadata: %{
        verdict: r.verdict,
        implementer_transcript_received: r.implementer_transcript_received
      }
    }
  end

  defp human_decision_node(%M0HumanDecision{} = hd) do
    %{
      id: hd.id,
      kind: "HumanDecision",
      label: "Human: #{hd.decision}",
      canonical_digest: hd.semantic_digest,
      attention: "COMPLETE",
      proposed: false,
      lifecycle_scope: nil,
      metadata: %{
        decision: hd.decision
      }
    }
  end

  defp patch_evidence_node(%M0PatchEvidence{} = pe) do
    %{
      id: pe.id,
      kind: "PatchEvidence",
      label: "Patch Applied",
      canonical_digest: pe.semantic_digest,
      attention: "COMPLETE",
      proposed: false,
      lifecycle_scope: nil,
      metadata: %{
        effect: pe.effect,
        post_state_digest: pe.post_state_digest
      }
    }
  end

  defp lifecycle_scope_from_base(nil), do: nil
  defp lifecycle_scope_from_base(""), do: nil
  defp lifecycle_scope_from_base(base) when is_binary(base), do: "base:" <> base

  defp attention_for_proposal(_), do: "WORKING"
  defp attention_for_verification(%{status: :PASS}), do: "WORKING"
  defp attention_for_verification(%{status: :FAIL}), do: "FAILED"
  defp attention_for_verification(_), do: "BLOCKED"
  defp attention_for_review(%{verdict: :APPROVE}), do: "WORKING"
  defp attention_for_review(%{verdict: :REJECT}), do: "FAILED"
  defp attention_for_review(%{verdict: :REQUEST_REVISION}), do: "BLOCKED"
end