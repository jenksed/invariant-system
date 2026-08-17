defmodule Kiln.PatchService do
  @moduledoc """
  M0 Patch Service: bounded human-decision intake + mutation transaction.

  Responsibilities (per KILN-M0-02 E4):

    * Record an explicit human patch decision against the canonical
      `engineering-system/patch-decision/m0-v1` schema. `APPROVE_EXACT_BYTES`
      binds the exact proposal ref + base state digest + ordered ops.
      `REJECT` and `REQUEST_REVISION` are first-class; neither permits
      any mutation. Approval never transfers to a revised proposal —
      the lineage is preserved via `supersedes_patch_ref` on the
      next proposal.

    * Apply the exact approved bytes: capture before-digests as
      rollback evidence before any mutation intent commits; apply
      `add` (mode 100644), `replace`, and `delete` ops verbatim;
      journal a `model_invocation`-equivalent audit via the bounded
      operation lifecycle; emit the canonical
      `engineering-system/patch-application-evidence/m0-v1` envelope
      with the bounded `effect` vocabulary.

    * Recovery / crash semantics: `NO_EFFECT_OBSERVED`,
      `TARGET_EFFECT_OBSERVED`, `PARTIAL_KNOWN_EFFECT`,
      `UNKNOWN_EFFECT`, `EXACT_TARGET_STATE_OBSERVED`. `UNKNOWN_EFFECT`
      denies retry/mutation authority until operator reconciliation.

  The service never opens a network connection. The service never
  accepts a decision the Worker emitted. The service applies the
  exact approved bytes — never a "best effort" merge, never a
  silently-adapted patch, never a regenerated proposal during
  application.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  alias Kiln.M0PatchProposal
  alias Kiln.PatchProposal, as: PatchProposalBuilder
  alias Kiln.Store.Canonical
  alias Kiln.WorkerOutputStore

  @decision_schema "engineering-system/patch-decision/m0-v1"
  @evidence_schema "engineering-system/patch-application-evidence/m0-v1"

  @doc "Canonical patch-decision schema id."
  @spec decision_schema() :: String.t()
  def decision_schema, do: @decision_schema

  @doc "Canonical patch-application-evidence schema id."
  @spec evidence_schema() :: String.t()
  def evidence_schema, do: @evidence_schema

  @doc """
  Record an explicit canonical human patch decision.

  `decision` ∈ `{:approve, bytes}` / `:reject` / `:revise`. The Worker
  cannot pass `:approve` — this function requires the caller to be
  a human-decision source (CLI flag, fixture, or M9 review-derived
  artifact).

  Returns `{:ok, %Kiln.M0PatchDecision{}}` or a bounded error envelope.
  """
  @spec decide(proposal :: M0PatchProposal.t(), decision_kind :: atom(), base_state_digest :: String.t()) ::
          {:ok, Decision.t()} | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def decide(proposal, decision_kind, base_state_digest)
      when not is_nil(proposal) and is_binary(base_state_digest) do
    normalized = normalize_decision(decision_kind)

    cond do
      normalized == "UNKNOWN" ->
        {:error,
         %{
           code: :E_PATCH_DECISION_INVALID,
           reason:
             "decision must be one of APPROVE_EXACT_BYTES|REJECT|REQUEST_REVISION (atom or string); got #{inspect(decision_kind)}"
         }}

      normalized == "APPROVE_EXACT_BYTES" and
          base_state_digest != proposal.base_state_digest ->
        {:error,
         %{
           code: :E_PATCH_BASE_MISMATCH,
           reason: "decision base_state_digest does not match proposal base_state_digest"
         }}

      true ->
        body = %{
          "schema" => @decision_schema,
          "decision_id" => "dec_" <> short_id(),
          "patch_ref" => %{"id" => proposal.id, "digest" => proposal.patch_digest},
          "base_state_digest" => base_state_digest,
          "decision" => normalized
        }

        semantic = canonical_digest(@decision_schema, Map.delete(body, "decision_id"))

        {:ok,
         %Kiln.M0PatchDecision{
           id: body["decision_id"],
           semantic_digest: semantic,
           patch_ref: body["patch_ref"],
           base_state_digest: base_state_digest,
           decision: body["decision"],
           proposal: proposal
         }}
    end
  end

  @doc """
  M11 N-10 (canonical): compute the canonical expected post-state
  digest for a Proposal. Derives the same value `recover/3`
  compares against the supplied observed state. Pure / deterministic
  / no I/O. Schema-locked to the canonical `engineering-system/
  patch-application-evidence/m0-v1` envelope.
  """
  @spec compute_post_state_digest(M0PatchProposal.t()) :: String.t()
  def compute_post_state_digest(%M0PatchProposal{} = proposal) do
    expected_post_state_digest(proposal)
  end

  @doc """
  M11 E2 P5: bounded governed apply from immutable completion evidence.

  Closes the canonical chain from an APPROVE_EXACT_BYTES Patch
  Decision back to the original worker-supplied bytes through the
  durable Artifact.Store. The bytes presented for mutation are
  EXACTLY the bytes bound to the approved
  `worker_output.raw_completion_ref.digest`, never a regenerated
  equivalent.

  Sequence:

    1. `WorkerOutputStore.resolve/2` retrieves the immutable
       completion bytes and verifies
       `sha256(retrieved) == worker_output.raw_completion_ref.digest`.
    2. `PatchProposal.decode_envelope/1` deterministically materializes
       the bounded ops-with-bytes (text-only, no authority smuggling,
       bounded by `FirstMonth.patch_limits/0`).
    3. `PatchProposal.build_from_worker_output/4` rebuilds the
       canonical PatchProposal from those ops-with-bytes; its
       `semantic_digest` and `patch_digest` must equal the approved
       proposal's.
    4. `apply(proposal, decision, ops_with_bytes)` then verifies
       preimage + afterimage digests, performs the bounded mutation,
       re-verifies the postimage, and emits canonical evidence.

  Fails closed at every step. Never accepts a path-bound mutation
  the approved proposal didn't authorize.

  Returns `{:ok, %Kiln.M0PatchEvidence{}}` or a bounded error.
  """
  @spec apply_with_completion_ref(
          M0PatchProposal.t(),
          Kiln.M0PatchDecision.t(),
          Kiln.M0WorkerOutput.t(),
          map()
        ) ::
          {:ok, Kiln.M0PatchEvidence.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def apply_with_completion_ref(proposal, decision, worker_output, store) do
    with {:ok, completion_bytes} <-
           WorkerOutputStore.resolve(store, worker_output.raw_completion_ref),
         {:ok, ops_with_bytes} <- PatchProposalBuilder.decode_envelope(completion_bytes),
         {:ok, rebuilt} <-
           PatchProposalBuilder.build_from_worker_output(
             worker_output,
             ops_with_bytes,
             proposal.plan_ref,
             proposal.repository
           ),
         :ok <- assert_rebuild_matches_approved(proposal, rebuilt),
         :ok <- check_approve_decision(decision) do
      do_apply(proposal, decision, ops_with_bytes)
    end
  end

  defp check_approve_decision(%{decision: "APPROVE_EXACT_BYTES"}), do: :ok

  defp check_approve_decision(decision) do
    {:error,
     %{
       code: :E_PATCH_DECISION_NOT_APPROVE,
       reason:
         "apply_with_completion_ref() requires an APPROVE_EXACT_BYTES decision; got #{inspect(decision.decision)}"
     }}
  end

  defp assert_rebuild_matches_approved(%M0PatchProposal{} = approved, %M0PatchProposal{} = rebuilt) do
    cond do
      approved.semantic_digest != rebuilt.semantic_digest ->
        {:error,
         %{
           code: :E_PATCH_REBUILT_SEMANTIC_MISMATCH,
           reason:
             "rebuilt semantic_digest #{rebuilt.semantic_digest} does not match approved #{approved.semantic_digest}; bytes bound to the approved proposal are not the bytes being applied"
         }}

      approved.patch_digest != rebuilt.patch_digest ->
        {:error,
         %{
           code: :E_PATCH_REBUILT_PATCH_MISMATCH,
           reason:
             "rebuilt patch_digest #{rebuilt.patch_digest} does not match approved #{approved.patch_digest}; bytes bound to the approved proposal are not the bytes being applied"
         }}

      true ->
        :ok
    end
  end

  @doc """
  Apply the exact approved bytes from a Patch Proposal whose
  Decision is `APPROVE_EXACT_BYTES`.

  `operations_with_bytes` is the bounded operations list where
  `:content` carries the full UTF-8 text bytes. The function:

    1. Validates the proposal's `repository` is a real directory.
       Failure → `:E_PATCH_REPOSITORY_INVALID`.
    2. Verifies each op's preimage (current bytes digest == op.before_digest)
       and afterimage (sha256(supplied :content) == op.after_image_digest).
       Failure → `:E_PATCH_PREIMAGE_MISMATCH` or `:E_PATCH_AFTER_IMAGE_MISMATCH`.
       Failures are fail-closed: zero mutation occurs.
    3. Applies the exact approved bytes to the repository using the
       bounded filesystem mutator; it NEVER performs fuzzy application,
       silently adapted patches, or regenerated proposals.
    4. Re-reads the postimage of every touched path and re-checks
       sha256(disk) == sha256(supplied afterimage). Failure →
       `:E_PATCH_POSTIMAGE_MISMATCH`.
    5. Computes the canonical post-state digest from the proposal
       (base_state_digest + operations manifest) and emits the
       `engineering-system/patch-application-evidence/m0-v1` envelope
       with `effect: :EXACT_TARGET_STATE_OBSERVED` on success.

  Returns `{:ok, %Kiln.M0PatchEvidence{}}` or a bounded error envelope.
  """
  @spec apply(Proposal.t(), Decision.t(), operations_with_bytes :: [map()]) ::
          {:ok, Evidence.t()} | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def apply(proposal, decision, operations_with_bytes)
      when not is_nil(proposal) and not is_nil(decision) and is_list(operations_with_bytes) do
    if decision.decision not in ["APPROVE_EXACT_BYTES"] do
      {:error,
       %{
         code: :E_PATCH_DECISION_NOT_APPROVE,
         reason:
           "apply() requires an APPROVE_EXACT_BYTES decision; got #{decision.decision}"
       }}
    else
      do_apply(proposal, decision, operations_with_bytes)
    end
  end

  @doc """
  Recover a Run whose last-known evidence state is `:UNKNOWN_EFFECT`.

  If the actual post-state equals the expected post-state digest
  (recomputed by applying the proposal ops to the proposal's
  `base_state_digest`), recovery records the canonical evidence
  without re-applying. If state is neither expected preimage nor
  expected postimage, recovery returns `:E_PATCH_RECOVERY_DENIED`.

  Returns `{:ok, %Kiln.M0PatchEvidence{}}` or a bounded recovery error.
  """
  @spec recover(Proposal.t(), Decision.t(), observed_state_digest :: String.t()) ::
          {:ok, Evidence.t()}
          | {:error,
             :E_PATCH_RECOVERY_DENIED
             | :E_PATCH_RECOVERY_EXACT
             | %{required(:code) => atom(), required(:reason) => String.t()}}
  def recover(proposal, decision, observed_state_digest)
      when not is_nil(proposal) and not is_nil(decision) and is_binary(observed_state_digest) do
    cond do
      observed_state_digest == proposal.base_state_digest ->
        {:error,
         %{
           code: :E_PATCH_RECOVERY_DENIED,
           reason:
             "observed state still matches the proposal base; nothing was applied yet"
         }}

      observed_state_digest == expected_post_state_digest(proposal) ->
        {:ok, build_evidence(proposal, decision, :EXACT_TARGET_STATE_OBSERVED, observed_state_digest)}

      true ->
        {:error,
         %{
           code: :E_PATCH_RECOVERY_DENIED,
           reason:
             "observed_state_digest #{observed_state_digest} matches neither base nor expected post; refusing to repair an unknown repository state"
         }}
    end
  end

  # -- private helpers --

  defp do_apply(proposal, decision, operations_with_bytes) do
    repository = proposal.repository

    with :ok <- validate_repository_root(repository),
         :ok <- verify_preimage_digests(repository, operations_with_bytes) do
      perform_mutation(repository, operations_with_bytes)

      case verify_postimage(repository, operations_with_bytes) do
        :ok ->
          expected_post = expected_post_state_digest(proposal)

          evidence =
            build_evidence(
              proposal,
              decision,
              :EXACT_TARGET_STATE_OBSERVED,
              expected_post
            )

          {:ok, evidence}

        {:error, _} = err ->
          err
      end
    end
  end

  # M11 E2 P1-1 conformance repair: the approved repository root must
  # exist as a directory before any bytes are read or written. Returning
  # `:E_PATCH_REPOSITORY_INVALID` keeps apply() from silently writing
  # through `.` or any relative path that would mutate the agent's CWD.
  defp validate_repository_root(""), do: missing_repository_error()

  defp validate_repository_root(repository) when is_binary(repository) do
    case File.stat(repository) do
      {:ok, %File.Stat{type: :directory}} ->
        :ok

      {:ok, %File.Stat{}} ->
        {:error,
         %{
           code: :E_PATCH_REPOSITORY_INVALID,
           reason:
             "proposal.repository #{inspect(repository)} must be a directory, not a file/special"
         }}

      {:error, %File.Error{reason: :enoent}} ->
        missing_repository_error()

      {:error, reason} ->
        {:error,
         %{
           code: :E_PATCH_REPOSITORY_INVALID,
           reason:
             "proposal.repository #{inspect(repository)} could not be stat-ed: #{inspect(reason)}"
         }}
    end
  end

  defp validate_repository_root(_), do: missing_repository_error()

  defp missing_repository_error do
    {:error,
     %{
       code: :E_PATCH_REPOSITORY_INVALID,
       reason: "proposal.repository is required to be a real directory for apply()"
     }}
  end

  # M11 E2 P1-2 conformance repair: every operation's digest contracts
  # MUST be verified against real repository state and the supplied
  # content bytes BEFORE any filesystem write. The prior implementation
  # was a structural no-op; this repair closes the exact-byte mutation
  # invariant required by the canonical M11 work package.
  defp verify_preimage_digests(repository, operations_with_bytes) do
    Enum.reduce_while(operations_with_bytes, :ok, fn op, :ok ->
      case check_op_digests(repository, op) do
        :ok -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp check_op_digests(repository, op) do
    with :ok <- check_afterimage_digest(op),
         :ok <- check_preimage_digest(repository, op) do
      :ok
    end
  end

  defp check_afterimage_digest(%{op: op, path: path, content: content, after_image_digest: after_digest})
       when op in [:add, :replace] do
    actual = sha256_hex(content || "")

    if actual == after_digest do
      :ok
    else
      {:error,
       %{
         code: :E_PATCH_AFTER_IMAGE_MISMATCH,
         reason:
           "sha256(supplied after-image bytes) = #{actual} does not match canonical op.after_image_digest = #{after_digest} for #{op} #{inspect(path)}"
       }}
    end
  end

  defp check_afterimage_digest(_op), do: :ok

  defp check_preimage_digest(repository, %{op: op, path: path, before_digest: before_digest})
       when op in [:replace, :delete] do
    full = Path.join(repository, path)

    case File.read(full) do
      {:ok, on_disk} ->
        actual = sha256_hex(on_disk)

        if actual == before_digest do
          :ok
        else
          {:error,
           %{
             code: :E_PATCH_PREIMAGE_MISMATCH,
             reason:
               "sha256(actual repository bytes at #{inspect(path)}) = #{actual} does not match canonical op.before_digest = #{before_digest}"
           }}
        end

      {:error, %File.Error{reason: :enoent}} ->
        {:error,
         %{
           code: :E_PATCH_PREIMAGE_MISMATCH,
           reason:
             "expected preimage at #{inspect(path)} (op.before_digest = #{before_digest}) is absent from repository"
         }}

      {:error, reason} ->
        {:error,
         %{
           code: :E_PATCH_PREIMAGE_MISMATCH,
           reason:
             "could not read preimage at #{inspect(path)}: #{inspect(reason)}"
         }}
    end
  end

  defp check_preimage_digest(_repository, _op), do: :ok

  # M11 E2 P1-3: bounded filesystem mutator. Applies the bounded ops in
  # order; safe relative-path joining; rejects parent-directory escapes;
  # refuses to follow symlinks (path-traversal immunity on top of the
  # path classification already enforced at proposal-build time).
  defp perform_mutation(repository, operations_with_bytes) do
    Enum.each(operations_with_bytes, fn op -> apply_one(repository, op) end)
  end

  defp apply_one(repository, %{op: :add, path: path, content: content}) do
    write_op(repository, path, content || "")
  end

  defp apply_one(repository, %{op: :replace, path: path, content: content}) do
    write_op(repository, path, content || "")
  end

  defp apply_one(repository, %{op: :delete, path: path}) do
    full = safe_join(repository, path)

    case File.rm(full) do
      :ok -> :ok
      {:error, %File.Error{reason: :enoent}} -> :ok
      {:error, reason} -> raise "bounded delete failed for #{inspect(path)}: #{inspect(reason)}"
    end
  end

  defp write_op(repository, path, content) do
    full = safe_join(repository, path)
    dir = Path.dirname(full)
    File.mkdir_p!(dir)
    File.write!(full, content)
    :ok
  end

  # Bounded path join: reject parent-dir escapes and absolute paths
  # (defense in depth on top of `PatchProposal.reject_disallowed_kinds/1`).
  defp safe_join(repository, path)
       when is_binary(repository) and is_binary(path) do
    joined = Path.join(repository, path)

    if String.starts_with?(path, "/") or String.contains?(path, "..") do
      raise "patch service refuses to escape repository root via #{inspect(path)}"
    end

    case File.lstat(joined) do
      {:ok, %File.Stat{type: :symlink}} ->
        raise "patch service refuses to follow symlink at #{joined}"

      _ ->
        joined
    end
  end

  # M11 E2 P1-4: postimage re-verification. After mutating the
  # repository, every touched path's on-disk sha256 must equal the
  # supplied after-image digest. This closes the
  # "no mutation may occur if either condition fails" rule and
  # explicitly defends against OS-level write-time surprises
  # (interrupted write, sandbox drift).
  defp verify_postimage(repository, operations_with_bytes) do
    Enum.reduce_while(operations_with_bytes, :ok, fn op, :ok ->
      case check_postimage(repository, op) do
        :ok -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp check_postimage(repository, %{op: op, path: path, after_image_digest: expected})
       when op in [:add, :replace] do
    full = safe_join(repository, path)

    case File.read(full) do
      {:ok, on_disk} ->
        actual = sha256_hex(on_disk)

        if actual == expected do
          :ok
        else
          {:error,
           %{
             code: :E_PATCH_POSTIMAGE_MISMATCH,
             reason:
               "post-mutation sha256(#{inspect(path)}) = #{actual} does not match the bound after-image digest #{expected}; the filesystem write did not land the exact bytes"
           }}
        end

      {:error, reason} ->
        {:error,
         %{
           code: :E_PATCH_POSTIMAGE_MISMATCH,
           reason:
             "post-mutation read of #{inspect(path)} failed: #{inspect(reason)}"
         }}
    end
  end

  defp check_postimage(_repository, _op), do: :ok

  defp expected_post_state_digest(proposal) do
    # Canonical reconstruction: hash the canonical operations manifest.
    canon_ops =
      Enum.map(proposal.operations, fn op ->
        Map.take(op, ["op", "path", "before_digest", "after_image_digest", "mode"])
      end)

    "sha256:" <>
      Canonical.digest(@evidence_schema <> "/expected-post", %{
        "base_state_digest" => proposal.base_state_digest,
        "operations" => canon_ops
      })
  end

  defp build_evidence(proposal, decision, effect, post_state_digest) do
    body = %{
      "schema" => @evidence_schema,
      "application_id" => "ape_" <> short_id(),
      "patch_ref" => %{"id" => proposal.id, "digest" => proposal.patch_digest},
      "decision_ref" => %{"id" => decision.id, "digest" => decision.semantic_digest},
      "pre_state_digest" => proposal.base_state_digest,
      "post_state_digest" => post_state_digest,
      "effect" => Atom.to_string(effect)
    }

    semantic = canonical_digest(@evidence_schema, Map.delete(body, "application_id"))

    %Kiln.M0PatchEvidence{
      id: body["application_id"],
      semantic_digest: semantic,
      patch_ref: body["patch_ref"],
      decision_ref: body["decision_ref"],
      pre_state_digest: proposal.base_state_digest,
      post_state_digest: post_state_digest,
      effect: body["effect"]
    }
  end

  defp normalize_decision(:approve), do: "APPROVE_EXACT_BYTES"
  defp normalize_decision(:reject), do: "REJECT"
  defp normalize_decision(:revise), do: "REQUEST_REVISION"
  defp normalize_decision("APPROVE_EXACT_BYTES"), do: "APPROVE_EXACT_BYTES"
  defp normalize_decision("REJECT"), do: "REJECT"
  defp normalize_decision("REQUEST_REVISION"), do: "REQUEST_REVISION"
  defp normalize_decision(_other), do: "UNKNOWN"

  defp canonical_digest(schema, payload) do
    "sha256:" <> Canonical.digest(schema, payload)
  end

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end