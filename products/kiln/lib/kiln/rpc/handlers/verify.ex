defmodule Kiln.RPC.Handlers.Verify do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `verify.run`.

  Wraps the canonical `Kiln.M0VerificationResult.build/6` (m0_types.ex:374)
  which emits the `engineering-system/verification-result/m0-v1` envelope.

  This handler is for the bounded invocation of a registered verifier
  against a post-mutation state. It does NOT execute the verifier
  command itself — `Kiln.Verification.Supervision` (lib/kiln/verification/
  supervision.ex) owns that responsibility. The handler validates the
  envelope, calls the builder, and returns the canonical envelope.

  Verification is evidence, NOT authority. PASS does not auto-accept;
  a separate `human.decide` invocation is required for an authoritative
  transition (per WP-09 contract freeze §5 + §11).

  Required params:
    plan_ref               — bounded %{id, digest}
    patch_ref              — bounded %{id, digest}
    result_state_digest    — sha256:<64hex>
    registered_verifier    — bounded %{id, digest} (from VerifierRegistry)
    status                 — PASS | FAIL | TIMEOUT | ERROR
    evidence_refs          — non-empty list of bounded %{id, digest}

  Optional:
    idempotency_key        — idem_<32hex>  (envelope wins on conflict)
    request_digest         — sha256:<64hex>  (envelope wins on conflict)
    session_id             — ses_<32hex>  (for activity correlation)
    run_id                 — run_<32hex>  (for activity correlation)

  Scope (router.ex): orchestration:operate

  Bounded error codes:
    E_MISSING_FIELDS, E_INVALID_FIELD, E_INVALID_DIGEST,
    E_VERIFICATION_STATUS_INVALID, E_VERIFICATION_EVIDENCE_MISSING,
    E_STORE_UNAVAILABLE, E_VERIFICATION_BUILD_FAILED
  """

  alias Kiln.VerificationResult

  @required_param_keys [
    "plan_ref",
    "patch_ref",
    "result_state_digest",
    "registered_verifier",
    "status",
    "evidence_refs"
  ]

  @doc "Dispatch `verify.run`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("verify.run", params, opts) when is_map(params) and is_list(opts) do
    with :ok <- require_all(params, @required_param_keys),
         {:ok, result_state_digest} <- require_digest(params["result_state_digest"], "result_state_digest"),
         {:ok, plan_ref} <- require_artifact_ref(params["plan_ref"], "plan_ref"),
         {:ok, patch_ref} <- require_artifact_ref(params["patch_ref"], "patch_ref"),
         {:ok, verifier_ref} <- require_artifact_ref(params["registered_verifier"], "registered_verifier"),
         {:ok, status} <- require_status(params["status"]),
         {:ok, evidence_refs} <- require_evidence_refs(params["evidence_refs"]) do
      build_and_emit(
        plan_ref,
        patch_ref,
        result_state_digest,
        verifier_ref,
        status,
        evidence_refs,
        opts
      )
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- build + emit --

  defp build_and_emit(plan_ref, patch_ref, result_state_digest, verifier_ref, status, evidence_refs, _opts) do
    case VerificationResult.build(
           plan_ref,
           patch_ref,
           result_state_digest,
           verifier_ref,
           status,
           evidence_refs
         ) do
      {:ok, vr} ->
        {:ok,
         %{
           "verification_id" => vr.id,
           "semantic_digest" => vr.semantic_digest,
           "status" => Atom.to_string(vr.status),
           "result_state_digest" => vr.result_state_digest,
           "registered_verifier" => vr.registered_verifier,
           "evidence_refs" => vr.evidence_refs,
           "plan_ref" => vr.plan_ref,
           "patch_ref" => vr.patch_ref
         }}

      {:error, %{code: :E_VERIFICATION_STATUS_INVALID} = err} ->
        {:error, err}

      {:error, %{code: :E_VERIFICATION_EVIDENCE_MISSING} = err} ->
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

  defp require_status(status) when status in ~w(PASS FAIL TIMEOUT ERROR), do: {:ok, status}

  defp require_status(_) do
    {:error, %{code: :E_VERIFICATION_STATUS_INVALID, reason: "status must be one of PASS|FAIL|TIMEOUT|ERROR"}}
  end

  defp require_evidence_refs(refs) when is_list(refs) and length(refs) >= 1 do
    Enum.reduce_while(refs, {:ok, []}, fn ref, {:ok, acc} ->
      case require_artifact_ref(ref, "evidence_ref") do
        {:ok, r} -> {:cont, {:ok, [r | acc]}}
        err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      err -> err
    end
  end

  defp require_evidence_refs(_) do
    {:error, %{code: :E_VERIFICATION_EVIDENCE_MISSING, reason: "evidence_refs must be a non-empty list of %{id, digest} maps"}}
  end
end
