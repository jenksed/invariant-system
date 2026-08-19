defmodule Kiln.RPC.Handlers.HumanDecision do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `human.decide`.

  Wraps the canonical `Kiln.HumanDecision.build/5` (m9_review.ex:225)
  which emits the `engineering-system/human-decision/m0-v1` envelope.

  HumanDecision is the authoritative transition (WP-09 contract freeze
  §5 + §11). It is the explicit operator decision recorded in the
  durable journal; nothing else may cause a transition to
  `accepted/rejected`. UI affordances are NOT the security boundary —
  the daemon validates the envelope against current canonical state
  and rejects stale approvals.

  Required params:
    plan_ref             — bounded %{id, digest}
    patch_ref            — bounded %{id, digest}
    result_state_digest  — sha256:<64hex>
    review_ref           — bounded %{id, digest} | nil
    decision             — ACCEPT | REJECT | REQUEST_REVISION

  Optional:
    idempotency_key      — idem_<32hex>
    request_digest       — sha256:<64hex>
    session_id           — ses_<32hex>
    run_id               — run_<32hex>
    actor_id             — non-empty string (default: "rpc_operator")
    decision_source      — operator_explicit | system_assisted (default: operator_explicit)

  Scope (router.ex): orchestration:operate

  Bounded error codes:
    E_MISSING_FIELDS, E_INVALID_FIELD, E_INVALID_DIGEST,
    E_HUMAN_DECISION_INVALID, E_HUMAN_DECISION_FAILED
  """

  alias Kiln.HumanDecision

  @required_param_keys [
    "plan_ref",
    "patch_ref",
    "result_state_digest",
    "decision"
  ]

  @doc "Dispatch `human.decide`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("human.decide", params, opts) when is_map(params) and is_list(opts) do
    _ = opts
    with :ok <- require_all(params, @required_param_keys),
         {:ok, plan_ref} <- require_artifact_ref(params["plan_ref"], "plan_ref"),
         {:ok, patch_ref} <- require_artifact_ref(params["patch_ref"], "patch_ref"),
         {:ok, digest} <- require_digest(params["result_state_digest"], "result_state_digest"),
         {:ok, review_ref} <- require_optional_artifact_ref(params["review_ref"], "review_ref"),
         {:ok, decision} <- require_decision(params["decision"]) do
      build_and_emit(plan_ref, patch_ref, digest, review_ref, decision)
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- build + emit --

  defp build_and_emit(plan_ref, patch_ref, result_state_digest, review_ref, decision) do
    case HumanDecision.build(plan_ref, patch_ref, result_state_digest, review_ref, decision) do
      {:ok, hd_struct} ->
        {:ok,
         %{
           "human_decision_id" => hd_struct.id,
           "semantic_digest" => hd_struct.semantic_digest,
           "decision" => hd_struct.decision,
           "plan_ref" => hd_struct.plan_ref,
           "patch_ref" => hd_struct.patch_ref,
           "result_state_digest" => hd_struct.result_state_digest,
           "review_ref" => hd_struct.review_ref,
           "recorded_at" => hd_struct.recorded_at
         }}

      {:error, %{code: :E_HUMAN_DECISION_INVALID} = err} ->
        {:error, err}

      {:error, %{code: _} = err} ->
        {:error, err}
    end
  end

  # -- validators --

  defp require_all(params, keys) do
    missing = Enum.filter(keys, fn k -> not Map.has_key?(params, k) end)

    case missing do
      [] -> :ok
      _ -> {:error, %{code: :E_MISSING_FIELDS, reason: "missing required fields", fields: missing}}
    end
  end

  defp require_digest(value, field) when is_binary(value) do
    if Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
      {:ok, value}
    else
      {:error, %{code: :E_INVALID_DIGEST, reason: "#{field} must be sha256:<64hex>"}}
    end
  end

  defp require_digest(_, field) do
    {:error, %{code: :E_INVALID_FIELD, reason: "#{field} must be a sha256:<64hex> string"}}
  end

  defp require_artifact_ref(%{} = ref, field) do
    cond do
      not is_binary(ref["id"]) or byte_size(ref["id"]) == 0 ->
        {:error, %{code: :E_INVALID_FIELD, reason: "#{field}.id must be a non-empty string"}}

      not is_binary(ref["digest"]) or byte_size(ref["digest"]) == 0 ->
        {:error, %{code: :E_INVALID_FIELD, reason: "#{field}.digest must be a non-empty string"}}

      true ->
        {:ok, ref}
    end
  end

  defp require_artifact_ref(_, field) do
    {:error, %{code: :E_INVALID_FIELD, reason: "#{field} must be a %{id, digest} map"}}
  end

  defp require_optional_artifact_ref(nil, _), do: {:ok, nil}

  defp require_optional_artifact_ref(%{} = ref, field), do: require_artifact_ref(ref, field)

  defp require_decision(d) when d in ~w(ACCEPT REJECT REQUEST_REVISION), do: {:ok, d}

  defp require_decision(_) do
    {:error, %{code: :E_HUMAN_DECISION_INVALID, reason: "decision must be one of ACCEPT|REJECT|REQUEST_REVISION"}}
  end
end
