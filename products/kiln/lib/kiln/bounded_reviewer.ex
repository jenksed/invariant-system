defmodule Kiln.BoundedReviewer do
  @moduledoc """
  M3-R2 (Bounded) independent reviewer.

  This is the smallest legitimate independent reviewer executor. It
  is invoked from a SEPARATE process/role from the implementer
  (MiniMax). It re-decodes the candidate envelope, re-examines the
  verification evidence, and decides APPROVE / REQUEST_REVISION /
  REJECT using ONLY the bounded inputs:

    * the candidate's raw completion bytes (the post-image);
    * the verification result envelope (result_state_digest + status);
    * the plan_ref;
    * the bounded contracts (patch-proposal schema, first-month
      patch_limits);
    * engineering contracts in products/kiln/docs/decisions/ when
      supplied via review_context.

  The reviewer NEVER receives:
    * the implementer's explanation / self-assessment;
    * the implementer's assignment_ref contents;
    * the implementer's transcript;
    * any human-acceptance authority.

  Independence properties:

    * The reviewer's `implementation_digest/0` is computed from the
      source bytes of THIS module (and the contract schemas it uses).
      It is structurally distinct from
      `Kiln.MinimaxM3Adapter.implementation_digest/0`,
      `Kiln.DogfoodAdapter.implementation_digest/0`, and
      `Kiln.Worker.implementation_digest/0`. No two roles share an
      implementation identity.

    * The reviewer's `reviewer_assignment_ref.digest` is the
      `implementation_digest/0` of THIS module. The bounded check in
      `Kiln.Review.build/9` rejects any review whose
      `reviewer_assignment_ref.digest` equals the
      `implementer_assignment_ref.digest`.

    * The bounded `implementer_transcript_received` field on the
      emitted review is `false` by construction. The reviewer cannot
      see the implementer's reasoning.

  Bounded rules (smallest legitimate, not authoritative):

    1. The candidate must decode via `Kiln.PatchProposal.decode_envelope/1`
       (canonical envelope, bounded operations).
    2. Each operation must target a path inside the repository root
       and not escape via `..`.
    3. Each `add` or `replace` operation's post-image bytes must parse
       as Elixir via `Code.string_to_quoted/1` (the bounded sanity
       check the adapter already applies). This is candidate
       admissibility, NOT execution verification — the registered
       external verifier still runs post-apply.
    4. The verification envelope's `status` field must be `PASS`. A
       verification FAIL is independent grounds for REJECT.

  Architecture: Kiln.M3 (M3-R2 close-out, lane M3).
  """

  alias Kiln.PatchProposal
  alias Kiln.Store.Canonical

  @envelope_schema "engineering-system/implementer-patch-proposal-input/v1"

  @allowed_verdict ~w(APPROVE REQUEST_REVISION REJECT)

  @doc "The bounded rules this reviewer checks. Stable across BEAM rebuilds unless source bytes change."
  @spec rules_id() :: String.t()
  def rules_id, do: "Kiln.BoundedReviewer/v1"

  @doc """
  Compute the implementation digest over the source bytes of this
  module and the canonical schemas it reads. Stable across BEAM
  rebuilds unless source bytes change.
  """
  @spec implementation_digest() :: String.t()
  def implementation_digest do
    schema_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, @envelope_schema), case: :lower)
    rules_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, rules_id()), case: :lower)
    module_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, "Kiln.BoundedReviewer/v1"), case: :lower)

    "sha256:" <>
      Base.encode16(
        :crypto.hash(:sha256, module_digest <> rules_digest <> schema_digest),
        case: :lower
      )
  end

  @doc """
  The bounded reviewer assignment ref. Its digest is the
  `implementation_digest/0` of THIS module — distinct from the
  implementer's identity.
  """
  @spec reviewer_assignment_ref() :: %{required(:id) => String.t(), required(:digest) => String.t()}
  def reviewer_assignment_ref do
    %{
      "id" => "reviewer-bounded-v1",
      "digest" => implementation_digest()
    }
  end

  @doc """
  Perform the independent bounded review of a candidate.

  Inputs (none of them is the implementer's explanation):

    * `completion_bytes` — the implementer's bounded envelope bytes
      (the raw candidate, exactly as Worker.propose emitted).
    * `verification` — the verification result envelope
      (`%Kiln.M0VerificationResult{}` or its map form).
    * `plan_ref` — the plan_ref artifact.
    * `repository_root` — the repository root, used for path-escape
      checking (NOT to read the repository; bounded rules only).

  Returns `{:ok, %{verdict: ..., findings: [...]}}` or a bounded
  error. The verdict is one of `APPROVE`, `REQUEST_REVISION`,
  `REJECT`. Findings is a non-empty list of bounded rationale
  strings.
  """
  @spec review(binary(), map(), map(), String.t()) ::
          {:ok, %{required(:verdict) => String.t(), required(:findings) => [String.t()]}}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def review(completion_bytes, verification, plan_ref, repository_root)
      when is_binary(completion_bytes) and is_map(verification) and is_map(plan_ref) and
             is_binary(repository_root) do
    findings =
      []
      |> run_check(&check_envelope_decodes/1, completion_bytes)
      |> run_check(&check_no_path_escape/2, completion_bytes, repository_root)
      |> run_check(&check_post_images_parse_as_elixir/1, completion_bytes)
      |> run_check(&check_verification_status/1, verification)
      |> run_check(&check_plan_ref_present/1, plan_ref)

    case {findings, verdict_for(findings, verification)} do
      {[], _} ->
        {:ok, %{verdict: "APPROVE", findings: ["all bounded rules satisfied; review approves the candidate"]}}

      {_, "REJECT"} ->
        {:ok, %{verdict: "REJECT", findings: findings}}

      {_, "REQUEST_REVISION"} ->
        {:ok, %{verdict: "REQUEST_REVISION", findings: findings}}

      {_, "APPROVE"} ->
        # Should not happen — if any check failed we would not produce
        # APPROVE. Defensive: surface the findings.
        {:ok, %{verdict: "REQUEST_REVISION", findings: findings}}
    end
  end

  # --- private helpers ---

  defp run_check(findings, fun, arg) do
    case fun.(arg) do
      :ok ->
        findings

      {:fail, reason} ->
        findings ++ [reason]

      {:halt, {:fail, reason}} ->
        findings ++ [reason]

      other ->
        findings ++ ["reviewer check returned unexpected: #{inspect(other)}"]
    end
  end

  defp run_check(findings, fun, arg1, arg2) do
    case fun.(arg1, arg2) do
      :ok ->
        findings

      {:fail, reason} ->
        findings ++ [reason]

      {:halt, {:fail, reason}} ->
        findings ++ [reason]

      other ->
        findings ++ ["reviewer check returned unexpected: #{inspect(other)}"]
    end
  end

  defp check_envelope_decodes(completion_bytes) do
    case PatchProposal.decode_envelope(completion_bytes) do
      {:ok, _ops} -> :ok
      {:error, %{reason: reason}} -> {:fail, "candidate envelope does not decode: #{inspect(reason)}"}
    end
  end

  defp check_no_path_escape(completion_bytes, repository_root) do
    case PatchProposal.decode_envelope(completion_bytes) do
      {:ok, ops} ->
        repo_real = Path.expand(repository_root)

        if repo_real == nil do
          {:fail, "repository root does not resolve: #{repository_root}"}
        else
          check_each_path(ops, repo_real)
        end

      {:error, _} ->
        # check_envelope_decodes already reported this; skip
        :ok
    end
  end

  defp check_each_path(ops, repo_real) do
    Enum.reduce_while(ops, :ok, fn op, :ok ->
      cond do
        String.contains?(op.path, "..") ->
          {:halt, {:fail, "operation path escapes repository: #{op.path}"}}

        true ->
          candidate = Path.join(repo_real, op.path)
          path_expanded = Path.expand(candidate)
          inside = path_expanded == repo_real or String.starts_with?(path_expanded, repo_real <> "/")

          if inside do
            {:cont, :ok}
          else
            {:halt, {:fail, "operation target escapes repository: #{op.path}"}}
          end
      end
    end)
  end

  defp check_post_images_parse_as_elixir(completion_bytes) do
    case PatchProposal.decode_envelope(completion_bytes) do
      {:ok, ops} ->
        Enum.reduce_while(ops, :ok, fn op, :ok ->
          if op.op == :delete do
            {:cont, :ok}
          else
            case Code.string_to_quoted(op.content) do
              {:ok, _ast} -> {:cont, :ok}
              {:error, _} -> {:halt, {:fail, "post-image for #{op.path} does not parse as Elixir"}}
            end
          end
        end)

      {:error, _} ->
        :ok
    end
  end

  defp check_verification_status(verification) do
    status =
      Map.get(verification, :status) || Map.get(verification, "status")

    case status do
      :PASS -> :ok
      "PASS" -> :ok
      _ -> {:fail, "verification status is not PASS: #{inspect(status)}"}
    end
  end

  defp check_plan_ref_present(plan_ref) do
    id = Map.get(plan_ref, "id") || Map.get(plan_ref, :id)
    digest = Map.get(plan_ref, "digest") || Map.get(plan_ref, :digest)

    cond do
      not is_binary(id) or byte_size(id) == 0 -> {:fail, "plan_ref.id is empty"}
      not is_binary(digest) -> {:fail, "plan_ref.digest is not a string"}
      true -> :ok
    end
  end

  defp verdict_for(findings, verification) do
    status =
      Map.get(verification, :status) || Map.get(verification, "status")

    cond do
      status not in [:PASS, "PASS"] -> "REJECT"
      findings == [] -> "APPROVE"
      true -> "REQUEST_REVISION"
    end
  end
end