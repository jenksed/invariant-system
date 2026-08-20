defmodule Temper.AttentionProjection do
  @moduledoc """
  M4 — derived operator-projection layer (Temper side).

  This module derives *operator-facing* classifications (attention
  state, label strings) from a `Kiln.GraphProjection`. It does NOT
  modify the canonical graph; the canonical graph remains the
  authority.

  Attention states are derived, NOT canonical Kiln facts. The
  classification rules are:

    WORKING          — operation is in progress
    BLOCKED          — operation cannot proceed (REQUEST_REVISION verdict)
    FAILED           — bounded failure (FAIL status or REJECT verdict)
    WAITING_FOR_HUMAN — bounded canonical state (record_pending_decision
                         has advanced the run; human acceptance required)
    COMPLETE         — bounded completion recorded

  These labels are useful for the UI but are NOT properties of the
  underlying M0 envelopes. The M0 envelopes have their own status
  fields (`:PASS | :FAIL | :TIMEOUT | :ERROR` for verification, etc.);
  the attention label is a Temper interpretation that may change
  without the canonical state changing.
  """

  alias Kiln.GraphProjection

  @type attention :: String.t()
  @type state :: %{
          required(:id) => String.t(),
          required(:label) => String.t(),
          required(:attention) => attention(),
          required(:explanation) => String.t()
        }

  @type env :: %{
          required(:node_id) => String.t(),
          required(:run_state) => atom() | nil,
          required(:verification_status) => atom() | nil,
          required(:review_verdict) => atom() | nil,
          required(:human_decision) => atom() | nil,
          required(:patch_evidence) => map() | nil
        }

  @attention_states ~w(WORKING BLOCKED FAILED WAITING_FOR_HUMAN COMPLETE)

  @doc "All possible attention states."
  @spec attention_states() :: [String.t()]
  def attention_states, do: @attention_states

  @doc """
  Classify the run_state into an attention label.

  The classification is purely derived from the inputs; the
  canonical state is preserved by the caller.
  """
  @spec classify_run_state(atom() | nil) :: attention()
  def classify_run_state(:waiting_for_user), do: "WAITING_FOR_HUMAN"
  def classify_run_state(:ready), do: "COMPLETE"
  def classify_run_state(:running), do: "WORKING"
  def classify_run_state(:blocked), do: "BLOCKED"
  def classify_run_state(:failed), do: "FAILED"
  def classify_run_state(_), do: "WORKING"

  @doc """
  Build a derived operator view for the entire projection. Returns
  a list of states (one per projection node) plus a summary of
  nodes that need attention.

  The `env` is a flat map of canonical facts that the projection
  may not directly carry (run_state, current verification status,
  etc.). Missing keys are tolerated.
  """
  @spec project(GraphProjection.projection(), env()) :: %{
          required(:states) => [state()],
          required(:attention_required) => [state()],
          required(:summary) => map()
        }
  def project(projection, env \\ %{}) do
    by_id = Map.new(projection.nodes, &{&1.id, &1})
    states = Enum.map(projection.nodes, fn node -> derive_state(node, by_id, env) end)

    attention_required =
      Enum.filter(states, fn s -> s.attention in ["BLOCKED", "FAILED", "WAITING_FOR_HUMAN"] end)

    summary = %{
      total_nodes: length(states),
      waiting_for_human: length(Enum.filter(states, &(&1.attention == "WAITING_FOR_HUMAN"))),
      blocked: length(Enum.filter(states, &(&1.attention == "BLOCKED"))),
      failed: length(Enum.filter(states, &(&1.attention == "FAILED"))),
      complete: length(Enum.filter(states, &(&1.attention == "COMPLETE"))),
      working: length(Enum.filter(states, &(&1.attention == "WORKING")))
    }

    %{states: states, attention_required: attention_required, summary: summary}
  end

  # --- per-node state derivation ---

  defp derive_state(node, by_id, env) do
    attention = attention_for(node, env)
    label = label_for(node)
    explanation = explanation_for(node, attention, by_id, env)

    %{
      id: node.id,
      label: label,
      attention: attention,
      explanation: explanation
    }
  end

  defp attention_for(%{kind: "WorkerOutput"}, _env), do: "WORKING"
  defp attention_for(%{kind: "PatchProposal"}, _env), do: "WORKING"
  defp attention_for(%{kind: "VerificationResult", metadata: %{status: :PASS}}, _env), do: "WORKING"
  defp attention_for(%{kind: "VerificationResult", metadata: %{status: :FAIL}}, _env), do: "FAILED"
  defp attention_for(%{kind: "VerificationResult"}, _env), do: "BLOCKED"
  defp attention_for(%{kind: "Review", metadata: %{verdict: :APPROVE}}, _env), do: "WORKING"
  defp attention_for(%{kind: "Review", metadata: %{verdict: :REJECT}}, _env), do: "FAILED"
  defp attention_for(%{kind: "Review", metadata: %{verdict: :REQUEST_REVISION}}, _env), do: "BLOCKED"
  defp attention_for(%{kind: "HumanDecision"}, env) do
    if env[:human_decision] in [:WAITING, nil] do
      "WAITING_FOR_HUMAN"
    else
      "COMPLETE"
    end
  end
  defp attention_for(%{kind: "PatchEvidence"}, _env), do: "COMPLETE"
  defp attention_for(%{kind: "EngineeringObjective"}, _env), do: "WORKING"
  defp attention_for(_, _env), do: "WORKING"

  defp label_for(%{kind: "WorkerOutput"}), do: "Worker"
  defp label_for(%{kind: "PatchProposal"}), do: "Patch"
  defp label_for(%{kind: "VerificationResult", metadata: %{status: :PASS}}), do: "Verification ✓"
  defp label_for(%{kind: "VerificationResult", metadata: %{status: :FAIL}}), do: "Verification ✗"
  defp label_for(%{kind: "Review", metadata: %{verdict: :APPROVE}}), do: "Review ✓"
  defp label_for(%{kind: "Review", metadata: %{verdict: :REJECT}}), do: "Review ✗"
  defp label_for(%{kind: "Review", metadata: %{verdict: :REQUEST_REVISION}}), do: "Review ↻"
  defp label_for(%{kind: "HumanDecision"}), do: "Human"
  defp label_for(%{kind: "PatchEvidence"}), do: "Applied"
  defp label_for(%{kind: "EngineeringObjective"}), do: "Objective"
  defp label_for(%{kind: other}), do: other

  defp explanation_for(_node, "FAILED", _by_id, _env) do
    "Completion blocked"
  end

  defp explanation_for(_node, "WAITING_FOR_HUMAN", _by_id, _env) do
    "YOUR CALL"
  end

  defp explanation_for(_node, "BLOCKED", _by_id, _env) do
    "awaiting revision"
  end

  defp explanation_for(_node, "COMPLETE", _by_id, _env) do
    "complete"
  end

  defp explanation_for(_node, "WORKING", _by_id, _env) do
    ""
  end
end
