defmodule Kiln.CLI do
  @moduledoc """
  The foundation CLI dispatcher.

  The CLI exposes a tiny P1-S01 surface (`start`, `status`, `inspect`,
  `cancel`, `resume`) over the accepted `Kiln.Workflow` boundary. Every
  command routes through `Kiln.Workflow` for application work and
  `Kiln.CLI.Runtime` for store lifecycle only. The CLI never reaches
  into the internal domain modules, the journal commit path, the restart
  classifier, or the projection rebuild path directly.

  Run a single command through `run/1`. The return value is a
  `{Result.t(), exit_code}` tuple so the caller (the `mix kiln` Mix
  task) can set the process exit code. Help and version are produced by
  the renderer so they share the same envelope as everything else.

  The dispatcher is non-authoritative: it never mutates the journal, the
  Store, or the projection directly. It never reads the Repository, the
  provider, the transcript, or external Commands, and never applies a
  Patch or accepts completion.
  """

  alias Kiln.CLI.{ErrorMap, Request, Result, Runtime}
  alias Kiln.Domain.Error
  alias Kiln.M0Currentness
  alias Kiln.OperationLifecycle
  alias Kiln.Workflow

  @supported_commands Request.commands()
  @version Kiln.version()

  @nonterminal_operation_states OperationLifecycle.nonterminal_states()
                                |> Enum.map(&Atom.to_string/1)

  @doc "Run a parsed request and return `{result, exit_code}`."
  @spec run(Request.t()) :: {Result.t(), non_neg_integer()}
  def run(%Request{show_version: true}),
    do: {version_result(), 0}

  def run(%Request{show_help: true}),
    do: {help_result(), 0}

  def run(%Request{command: command}) when command not in @supported_commands do
    result =
      Result.error(atom_to_command(command), :unsupported,
        errors: [
          Result.to_error(%{
            code: :unsupported_command,
            message: "the command is not available in the foundation CLI"
          })
        ]
      )

    {result, result.exit_code}
  end

  def run(%Request{} = request), do: dispatch(request)

  # -- dispatch --

  defp dispatch(%Request{} = request) do
    case request.command do
      :start -> run_writable(request, &dispatch_start/2)
      :status -> run_readonly(request, &dispatch_status/2)
      :inspect -> run_readonly(request, &dispatch_inspect/2)
      :cancel -> run_writable(request, &dispatch_cancel/2)
      :resume -> run_readonly(request, &dispatch_resume/2)
      :supervise -> run_supervise(request)
      :candidate_invocation -> run_candidate_invocation(request)
      :candidate_invocation_digest -> run_candidate_invocation_digest(request)
      :worker_propose -> run_worker_propose(request)
      :patch_decide -> run_patch_decide(request)
      :patch_apply -> run_patch_apply(request)
      :patch_apply_governed -> run_patch_apply_governed(request)
      :patch_recover -> run_patch_recover(request)
      :verify_run -> run_verify_run(request)
      :review_propose -> run_review_propose(request)
      :human_decide -> run_human_decide(request)
    end
  end

  # -- command: candidate-invocation-digest --
  #
  # Pure computation. Returns the recorded adapter implementation digest
  # through the standard CLI Result envelope. No Store, no Journal, no
  # Workflow, no Provider, no Repository, no Patch, no Transcript.
  # KILN-M0-01 (E4) public consumer-visible surface.

  defp run_candidate_invocation_digest(%Request{} = request) do
    request
    |> dispatch_candidate_invocation_digest()
    |> normalize_dispatch_result(request)
  end

  defp dispatch_candidate_invocation_digest(%Request{} = _request) do
    digest = Kiln.MinimaxM3Adapter.implementation_digest()

    {:ok,
     Result.ok("candidate-invocation-digest",
       data: %{"adapter_implementation_digest" => digest}
     )}
  end

  # -- command: worker-propose --
  #
  # KILN-M0-02 E2/E5 + M11 E2 P2: bounded IMPLEMENTER attempt driven
  # by an Intelligence Assignment. The CLI is the consumer-visible
  # surface; Worker.validate_binding/3 enforces dispatch-time
  # qualification revalidation. Worker.propose/5 emits the canonical
  # Worker Output envelope; the CLI also persists the bounded
  # completion bytes to the canonical Artifact.Store and rewires
  # raw_completion_ref to the durable Artifact identity.
  defp run_worker_propose(%Request{} = request) do
    case Runtime.open(request.kiln_home, :write) do
      {:ok, :ready} ->
        try do
          dispatch_worker_propose(request)
        after
          Runtime.stop()
        end

      {:absent} ->
        {:error, absent_result(request)}

      {:blocked, state, _error} ->
        {:error, blocked_result(request, state)}
    end
  end

  defp dispatch_worker_propose(%Request{options: opts} = request) do
    with {:ok, assignment} <- load_json(opts["assignment"], "assignment"),
         {:ok, eligibility} <- load_json(opts["eligibility"], "eligibility"),
         {:ok, request_attrs} <- load_json(opts["request"], "request"),
         {:ok, plan_ref} <- load_plan_ref(opts["plan"]),
         profile_digest <- assignment["profile_ref"]["digest"],
         {:ok, profile} <- resolve_profile(profile_digest),
         {:ok, store} <- ready_store(request),
         {:ok, output} <-
           Kiln.Worker.propose(
             assignment,
             eligibility,
             profile,
             request_attrs,
             opts["repository"] || "."
           ),
         {:ok, status, rewired} <- Kiln.WorkerOutputStore.publish(store, output) do
      out_path = opts["out"] || default_out("worker_output.json")

      File.write!(
        out_path,
        Jason.encode!(output_to_map(rewired))
      )

      {:ok,
       Result.ok("worker-propose",
         data: %{
           "worker_output_id" => rewired.id,
           "semantic_digest" => rewired.semantic_digest,
           "raw_completion_ref" => rewired.raw_completion_ref,
           "raw_completion_status" => Atom.to_string(status),
           "parsed_candidate_digest" => rewired.parsed_candidate_digest,
           "base_commit" => rewired.base_commit,
           "base_state_digest" => rewired.base_state_digest,
           "adapter_implementation_digest" => rewired.adapter_implementation_digest
         },
         next_actions:
           navigation_actions("worker-propose") ++
             [
               Result.next_action(
                 "patch-decide",
                 "review the worker output and emit a patch decision"
               )
             ]
       )}
    else
      {:error, %Result{} = result} -> {:error, result}
      {:error, %{code: code, reason: reason}} when is_atom(code) ->
        {:error,
         Result.error("worker-propose", :denied,
           errors: [Result.to_error(%{code: code, message: reason})]
         )}

      {:error, %Kiln.Store.Error{} = err} ->
        {:error, error_result_tuple(%Request{command: :worker_propose}, err)}
    end
  end

  # -- command: patch-decide --
  #
  # KILN-M0-02 E4: bounded human patch decision. The CLI is the
  # human-decision source for M8; the Worker cannot pass --decision
  # approve. `--decision` is bounded to APPROVE_EXACT_BYTES / REJECT /
  # REQUEST_REVISION. Approval binds to the proposal's base_state_digest.
  defp run_patch_decide(%Request{options: opts}) do
    with {:ok, proposal_map} <- load_json(opts["proposal"], "proposal"),
         {:ok, proposal} <- build_proposal_from_map(proposal_map),
         decision_kind <- parse_decision_kind(opts["decision"]),
         :ok <- validate_decision_kind(decision_kind),
         {:ok, decision} <-
           Kiln.PatchService.decide(proposal, decision_kind, proposal.base_state_digest) do
      out_path = opts["out"] || default_out("patch_decision.json")

      File.write!(
        out_path,
        Jason.encode!(decision_to_map(decision))
      )

      is_approve = decision.decision == "APPROVE_EXACT_BYTES"

      {:ok,
       Result.ok("patch-decide",
         data: %{
           "decision_id" => decision.id,
           "semantic_digest" => decision.semantic_digest,
           "decision" => decision.decision,
           "patch_ref" => decision.patch_ref,
           "base_state_digest" => decision.base_state_digest
         },
         next_actions:
           if is_approve do
             navigation_actions("patch-decide") ++
               [
                 Result.next_action(
                   "patch-apply",
                   "apply the approved exact bytes"
                 )
               ]
           else
             navigation_actions("patch-decide")
           end
       )}
    else
      {:error, %Result{} = result} -> {:error, result}
      {:error, %{code: code, reason: reason}} when is_atom(code) ->
        {:error,
         Result.error("patch-decide", :denied,
           errors: [Result.to_error(%{code: code, message: reason})]
         )}
    end
  end

  # -- command: patch-apply --
  #
  # KILN-M0-02 E4: apply the exact approved bytes after explicit
  # APPROVE_EXACT_BYTES decision. Emits patch-application-evidence.
  # Refuses REJECT / REQUEST_REVISION decisions with a bounded error.
  defp run_patch_apply(%Request{options: opts}) do
    with {:ok, decision_map} <- load_json(opts["decision"], "decision"),
         {:ok, proposal_map} <- load_json(opts["proposal"], "proposal"),
         {:ok, operations_with_bytes} <- load_json(opts["operations"], "operations"),
         {:ok, proposal} <- build_proposal_from_map(proposal_map),
         {:ok, decision} <- build_decision_from_map(decision_map, proposal) do
      case Kiln.PatchService.apply(proposal, decision, operations_with_bytes) do
        {:ok, evidence} ->
          out_path = opts["out"] || default_out("patch_application_evidence.json")
          File.write!(out_path, Jason.encode!(evidence_to_map(evidence)))

          {:ok,
           Result.ok("patch-apply",
             data: %{
               "application_id" => evidence.id,
               "semantic_digest" => evidence.semantic_digest,
               "patch_ref" => evidence.patch_ref,
               "decision_ref" => evidence.decision_ref,
               "pre_state_digest" => evidence.pre_state_digest,
               "post_state_digest" => evidence.post_state_digest,
               "effect" => evidence.effect
             },
             next_actions:
               navigation_actions("patch-apply") ++
                 [
                   Result.next_action(
                     "patch-recover",
                     "if the run died between mutation and evidence, run recovery"
                   )
                 ]
           )}

        {:error, %{code: code, reason: reason}} when is_atom(code) ->
          {:error,
           Result.error("patch-apply", :failed,
             errors: [Result.to_error(%{code: code, message: reason})]
           )}
      end
    else
      {:error, %Result{} = result} -> {:error, result}
    end
  end

  # -- command: patch-recover --
  #
  # KILN-M0-02 E4: bounded recovery from a non-terminal M8 state.
  # Refuses to repair an unknown repository state. Accepts a
  # known post-state digest and re-emits the canonical evidence.
defp run_patch_recover(%Request{options: opts}) do
    with {:ok, proposal_map} <- load_json(opts["proposal"], "proposal"),
         {:ok, decision_map} <- load_json(opts["decision"], "decision"),
         {:ok, proposal} <- build_proposal_from_map(proposal_map),
         {:ok, decision} <- build_decision_from_map(decision_map, proposal) do
      observed_digest = opts["observed-state-digest"]

      if not is_binary(observed_digest) do
        {:error, usage_result("--observed-state-digest is required")}
      else
        case Kiln.PatchService.recover(proposal, decision, observed_digest) do
        {:ok, evidence} ->
          out_path = opts["out"] || default_out("patch_recovery_evidence.json")
          File.write!(out_path, Jason.encode!(evidence_to_map(evidence)))

          {:ok,
           Result.ok("patch-recover",
             data: %{
               "application_id" => evidence.id,
               "semantic_digest" => evidence.semantic_digest,
               "effect" => evidence.effect,
               "post_state_digest" => evidence.post_state_digest
             },
             next_actions: navigation_actions("patch-recover")
           )}

        {:error, %{code: code, reason: reason}} when is_atom(code) ->
          {:error,
           Result.error("patch-recover", :failed,
             errors: [Result.to_error(%{code: code, message: reason})]
           )}
        end
      end
    else
      {:error, %Result{} = result} -> {:error, result}
    end
  end

  # -- command: patch-apply-governed --
  #
  # M11 E2 (Phases 5+6): bounded governed apply from immutable
  # completion evidence. The CLI opens the canonical Artifact Store
  # (via `Runtime.open`), re-materializes the worker-supplied bytes
  # from the durable Artifact, verifies the rebuilt digest matches
  # the approved Patch, then delegates to `PatchService.apply/3` for
  # the bounded real-disk mutation. The bytes applied are EXACTLY the
  # bytes bound to the approved worker_output.raw_completion_ref.
  defp run_patch_apply_governed(%Request{} = request) do
    case Runtime.open(request.kiln_home, :read) do
      {:ok, :ready} ->
        try do
          dispatch_patch_apply_governed(request)
        after
          Runtime.stop()
        end

      {:absent} ->
        {:error, absent_result(request)}

      {:blocked, state, _error} ->
        {:error, blocked_result(request, state)}
    end
  end

  defp dispatch_patch_apply_governed(%Request{options: opts} = request) do
    with {:ok, proposal_map} <- load_json(opts["proposal"], "proposal"),
         {:ok, proposal} <- build_proposal_from_map(proposal_map),
         {:ok, decision_map} <- load_json(opts["decision"], "decision"),
         {:ok, decision} <- build_decision_from_map(decision_map, proposal),
         {:ok, wo_map} <- load_json(opts["worker-output"], "worker-output"),
         {:ok, worker_output} <- build_worker_output_from_map(wo_map),
         {:ok, store} <- ready_store(request),
         {:ok, evidence} <-
           Kiln.PatchService.apply_with_completion_ref(
             proposal,
             decision,
             worker_output,
             store
           ) do
      out_path = opts["out"] || default_out("patch_application_evidence.json")

      File.write!(out_path, Jason.encode!(evidence_to_map(evidence)))

      {:ok,
       Result.ok("patch-apply-governed",
         data: %{
           "application_id" => evidence.id,
           "semantic_digest" => evidence.semantic_digest,
           "patch_ref" => evidence.patch_ref,
           "decision_ref" => evidence.decision_ref,
           "pre_state_digest" => evidence.pre_state_digest,
           "post_state_digest" => evidence.post_state_digest,
           "effect" => evidence.effect
         },
         next_actions: navigation_actions("patch-apply-governed")
       )}
    else
      {:error, %Result{} = result} -> {:error, result}

      {:error, %{code: code, reason: reason}} when is_atom(code) ->
        {:error,
         Result.error("patch-apply-governed", :failed,
           errors: [Result.to_error(%{code: code, message: reason})]
         )}

      {:error, %Kiln.Store.Error{} = err} ->
        {:error, error_result_tuple(%Request{command: :patch_apply_governed}, err)}
    end
  end

  defp build_worker_output_from_map(%{
         "worker_output_id" => id,
         "semantic_digest" => semantic,
         "attempt_ref" => attempt_ref,
         "assignment_ref" => assignment_ref,
         "profile_ref" => profile_ref,
         "raw_completion_ref" => raw_completion_ref,
         "parsed_candidate_digest" => parsed,
         "base_state_digest" => base_state_digest
       } = map)
       when is_binary(id) and is_binary(semantic) and is_map(raw_completion_ref) do
    {:ok,
     %Kiln.M0WorkerOutput{
       id: id,
       semantic_digest: semantic,
       attempt_ref: attempt_ref,
       assignment_ref: assignment_ref,
       profile_ref: profile_ref,
       output_kind: map["output_kind"] || "PATCH_CANDIDATE",
       raw_completion_ref: raw_completion_ref,
       parsed_candidate_digest: parsed,
       completion_bytes: decode_hex_bytes(map["completion_bytes"]),
       base_commit: map["base_commit"],
       base_state_digest: base_state_digest,
       adapter_implementation_digest:
         map["adapter_implementation_digest"] || "sha256:" <> String.duplicate("0", 64)
     }}
  end

  defp build_worker_output_from_map(_),
    do: {:error, usage_result("worker-output JSON must carry raw_completion_ref + bounded identity fields")}

  defp decode_hex_bytes(nil), do: ""
  defp decode_hex_bytes(""), do: ""
  defp decode_hex_bytes(value) when is_binary(value), do: Base.decode16!(value, case: :lower)

  # -- command: verify-run --
  #
  # KILN-M0-03 E5: bounded verifier invocation against the
  # post-mutation state. Emits canonical verification-result/m0-v1.
  # Verification is evidence, not authority — PASS does not auto-accept.
  defp run_verify_run(%Request{options: opts}) do
    result_state_digest = opts["result-state-digest"]
    status = opts["status"]

    with {:ok, plan_ref} <- load_artifact_ref(opts["plan"], "plan"),
         {:ok, patch_ref} <- load_artifact_ref(opts["patch"], "patch"),
         true <- is_binary(result_state_digest),
         {:ok, verifier_ref} <- load_artifact_ref(opts["registered-verifier"], "registered-verifier"),
         true <- is_binary(status),
         {:ok, evidence_refs} <- load_evidence_refs(opts["evidence"]) do
      case Kiln.VerificationResult.build(
             plan_ref,
             patch_ref,
             result_state_digest,
             verifier_ref,
             status,
             evidence_refs
           ) do
        {:ok, vr} ->
          out_path = opts["out"] || default_out("verification_result.json")
          File.write!(out_path, Jason.encode!(Kiln.M0VerificationResult.to_map(vr)))

          {:ok,
           Result.ok("verify-run",
             data: %{
               "verification_id" => vr.id,
               "semantic_digest" => vr.semantic_digest,
               "status" => Atom.to_string(vr.status),
               "result_state_digest" => vr.result_state_digest,
               "registered_verifier" => vr.registered_verifier,
               "evidence_refs" => vr.evidence_refs
             },
             next_actions: navigation_actions("verify-run")
           )}

        {:error, %{code: code, reason: reason}} when is_atom(code) ->
          {:error,
           Result.error("verify-run", :denied,
             errors: [Result.to_error(%{code: code, message: reason})]
           )}
      end
    else
      {:error, %Result{} = result} -> {:error, result}
    end
  end

  # -- command: review-propose --
  #
  # KILN-M0-03 E5: bounded REVIEWER dispatch. The Reviewer must be
  # independently assigned (reviewer_assignment_ref.digest !=
  # implementer_assignment_ref.digest). The Reviewer context never
  # includes the IMPLEMENTER's transcript (implementer_transcript_received:
  # false is enforced by Kiln.Review.build/9).
  defp run_review_propose(%Request{options: opts}) do
    result_state_digest = opts["result-state-digest"]
    verdict = opts["verdict"]

    with {:ok, impl_assign} <- load_artifact_ref(opts["implementer-assignment"], "implementer-assignment"),
         {:ok, eligibility_doc} <- load_json(opts["eligibility"], "eligibility"),
         :ok <- check_reviewer_currentness(eligibility_doc),
         {:ok, plan_ref} <- load_artifact_ref(opts["plan"], "plan"),
         {:ok, patch_ref} <- load_artifact_ref(opts["patch"], "patch"),
         {:ok, verifier_ref} <- load_artifact_ref(opts["verification"], "verification"),
         true <- is_binary(result_state_digest),
         {:ok, reviewer_assign} <-
           load_artifact_ref(opts["reviewer-assignment"], "reviewer-assignment"),
         {:ok, context_manifest_ref} <-
           load_artifact_ref(opts["context-manifest"], "context-manifest"),
         true <- is_binary(verdict),
         {:ok, findings} <- load_findings(opts["findings"]) do
      case Kiln.Review.build(
             impl_assign,
             plan_ref,
             patch_ref,
             result_state_digest,
             verifier_ref,
             reviewer_assign,
             verdict,
             findings,
             context_manifest_ref
           ) do
        {:ok, review} ->
          out_path = opts["out"] || default_out("review.json")
          File.write!(out_path, Jason.encode!(Kiln.M0Review.to_map(review)))

          {:ok,
           Result.ok("review-propose",
             data: %{
               "review_id" => review.id,
               "semantic_digest" => review.semantic_digest,
               "verdict" => Atom.to_string(review.verdict),
               "implementer_transcript_received" =>
                 review.implementer_transcript_received,
               "findings" => review.findings
             },
             next_actions: navigation_actions("review-propose")
           )}

        {:error, %{code: code, reason: reason}} when is_atom(code) ->
          {:error,
           Result.error("review-propose", :denied,
             errors: [Result.to_error(%{code: code, message: reason})]
           )}
      end
    else
      {:error, %Result{} = result} -> {:error, result}
    end
  end

  # -- command: human-decide --
  #
  # KILN-M0-03 E5: bounded operator decision. Records the canonical
  # human-decision/m0-v1 envelope and emits the run-result-projection/m0-v1
  # complementing the v0 Run Result Envelope. HumanDecision is the
  # authoritative final decision; nothing infers it.
  defp run_human_decide(%Request{options: opts}) do
    result_state_digest = opts["result-state-digest"]
    review_ref = opts["review"]
    decision = opts["decision"]

    with {:ok, plan_ref} <- load_artifact_ref(opts["plan"], "plan"),
         {:ok, patch_ref} <- load_artifact_ref(opts["patch"], "patch"),
         true <- is_binary(result_state_digest),
         true <- is_nil(review_ref) or is_map(review_ref),
         true <- is_binary(decision) do
      case Kiln.HumanDecision.build(plan_ref, patch_ref, result_state_digest, review_ref, decision) do
        {:ok, hd_struct} ->
          out_path = opts["out"] || default_out("human_decision.json")
          File.write!(out_path, Jason.encode!(Kiln.M0HumanDecision.to_map(hd_struct)))

          {:ok,
           Result.ok("human-decide",
             data: %{
               "human_decision_id" => hd_struct.id,
               "semantic_digest" => hd_struct.semantic_digest,
               "decision" => Atom.to_string(hd_struct.decision),
               "recorded_at" => hd_struct.recorded_at
             },
             next_actions: navigation_actions("human-decide")
           )}

        {:error, %{code: code, reason: reason}} when is_atom(code) ->
          {:error,
           Result.error("human-decide", :denied,
             errors: [Result.to_error(%{code: code, message: reason})]
           )}
      end
    else
      {:error, %Result{} = result} -> {:error, result}
    end
  end

  # -- private helpers for M8 commands --

  defp load_json(path, field) when is_binary(path) do
    case Kiln.M0CommandLoader.load_json(path, field) do
      {:ok, doc} -> {:ok, doc}
      {:error, %{reason: reason}} -> {:error, usage_result(reason)}
    end
  end

  # C6: REVIEWER-dispatch currentness revalidation.
  # The M9 work package (E2) requires "current QUALIFIED eligibility" for the
  # REVIEWER. The M8 IMPLEMENTER-dispatch boundary revalidates this; the M9
  # REVIEWER-dispatch boundary did not. This helper applies the same
  # canonical 168-hour currentness check at the M9 dispatcher boundary.
  # IMPLEMENTER currentness does not substitute for REVIEWER currentness:
  # the reviewer eligibility loaded here is the REVIEWER's, not the
  # implementer's. The structural separation invariant (REVIEWER digest !=
  # IMPLEMENTER digest) is enforced by Kiln.Review.build/9.
  defp check_reviewer_currentness(eligibility_doc) when is_map(eligibility_doc) do
    if M0Currentness.within_currentness_window?(eligibility_doc) do
      :ok
    else
      M0Currentness.stale_error(eligibility_doc)
    end
  end

  defp check_reviewer_currentness(_eligibility_doc) do
    {:error, %{code: :E_QUALIFICATION_NOT_CURRENT, reason: "eligibility is missing or malformed at the reviewer dispatch boundary"}}
  end

  defp load_json(nil, field) do
    {:error, usage_result("--#{field} is required")}
  end

  defp load_plan_ref(nil), do: {:ok, %{"id" => "pln_default", "digest" => "sha256:" <> String.duplicate("0", 64)}}

  defp load_plan_ref(path) when is_binary(path) do
    load_json(path, "plan")
  end

  defp resolve_profile(digest) when is_binary(digest) do
    impl = Application.get_env(:kiln, :worker_profile_resolver, &default_profile_resolve/1)
    impl.(digest)
  end

  defp default_profile_resolve(digest) do
    case Kiln.M0CommandLoader.resolve_profile(digest) do
      {:ok, profile} -> {:ok, profile}
      {:error, _} -> {:error, usage_result("profile not found by digest")}
    end
  end

  defp return(value), do: {:ok, value}

  defp build_proposal_from_map(%{"operations" => ops} = map) do
    proposal = %Kiln.M0PatchProposal{
      id: map["patch_id"] || "pp_recovered",
      semantic_digest: map["semantic_digest"] || "sha256:" <> String.duplicate("0", 64),
      plan_ref: map["plan_ref"] || %{"id" => "pln_recovered", "digest" => ""},
      attempt_ref: map["attempt_ref"] || %{"id" => "att_recovered", "digest" => ""},
      repository: map["repository"] || ".",
      base_commit: map["base_commit"],
      base_state_digest: map["base_state_digest"] || "",
      operations: Enum.map(ops, &deserialize_op/1),
      patch_digest: map["patch_digest"] || "",
      metadata: map["metadata"] || %{}
    }

    {:ok, proposal}
  end

  defp build_proposal_from_map(_), do: {:error, usage_result("proposal JSON must contain operations")}

  defp deserialize_op(map) do
    %{
      "op" => map["op"],
      "path" => map["path"],
      "before_digest" => map["before_digest"],
      "after_image_digest" => map["after_image_digest"],
      "mode" => map["mode"]
    }
  end

  defp parse_decision_kind("APPROVE_EXACT_BYTES"), do: :approve
  defp parse_decision_kind("approve"), do: :approve
  defp parse_decision_kind("REJECT"), do: :reject
  defp parse_decision_kind("reject"), do: :reject
  defp parse_decision_kind("REQUEST_REVISION"), do: :revise
  defp parse_decision_kind("revise"), do: :revise
  defp parse_decision_kind(_), do: :unknown

  defp validate_decision_kind(:unknown) do
    {:error, usage_result("--decision must be one of: approve|reject|revise")}
  end

  defp validate_decision_kind(kind) when kind in [:approve, :reject, :revise], do: :ok

  defp build_decision_from_map(%{"decision" => "APPROVE_EXACT_BYTES"} = map, proposal) do
    decision = %Kiln.M0PatchDecision{
      id: map["decision_id"] || "dec_recovered",
      semantic_digest: map["semantic_digest"] || "",
      patch_ref: map["patch_ref"] || %{"id" => proposal.id, "digest" => proposal.patch_digest},
      base_state_digest: map["base_state_digest"] || proposal.base_state_digest,
      decision: "APPROVE_EXACT_BYTES",
      proposal: proposal
    }

    {:ok, decision}
  end

  defp build_decision_from_map(_, _),
    do: {:error, usage_result("decision JSON must include decision: APPROVE_EXACT_BYTES")}

  defp decision_to_map(%Kiln.M0PatchDecision{} = decision) do
    Map.from_struct(decision)
    |> Map.put(:proposal, nil)
  end

  defp evidence_to_map(%Kiln.M0PatchEvidence{} = evidence) do
    Map.from_struct(evidence)
  end

  defp default_out(name), do: Path.join(System.tmp_dir!(), name)

  defp output_to_map(%Kiln.M0WorkerOutput{} = output) do
    Map.from_struct(output)
    |> Map.update!(:completion_bytes, &Base.encode16(&1, case: :lower))
  end

  # M9 helpers — bounded loading for the verify/review/human-decide surfaces.
  # Every bounded loader is called here; the dispatcher never reaches
  # into Kiln internal modules directly.

  defp load_artifact_ref(path, field) when is_binary(path) do
    case Kiln.M0CommandLoader.load_json(path, field) do
      {:ok, %{"id" => id, "digest" => digest}} when is_binary(id) and is_binary(digest) ->
        {:ok, %{"id" => id, "digest" => digest}}

      {:ok, _other} ->
        {:error, usage_result("#{field} JSON must contain {id, digest} artifact ref")}

      {:error, %{reason: reason}} ->
        {:error, usage_result(reason)}
    end
  end

  defp load_artifact_ref(nil, field), do: {:error, usage_result("--#{field} is required")}

  defp load_evidence_refs(path) when is_binary(path) do
    case Kiln.M0CommandLoader.load_json(path, "evidence") do
      {:ok, refs} when is_list(refs) and refs != [] ->
        if Enum.all?(refs, &match?(%{"id" => _, "digest" => _}, &1)),
          do: {:ok, refs},
          else: {:error, usage_result("evidence_refs must be a list of {id, digest} objects")}

      {:ok, _} ->
        {:error, usage_result("evidence_refs must be a non-empty list")}

      {:error, %{reason: reason}} ->
        {:error, usage_result(reason)}
    end
  end

  defp load_evidence_refs(nil), do: {:error, usage_result("--evidence is required")}

  defp load_findings(path) when is_binary(path) do
    case Kiln.M0CommandLoader.load_json(path, "findings") do
      {:ok, list} when is_list(list) and list != [] ->
        if Enum.all?(list, &is_binary/1),
          do: {:ok, list},
          else: {:error, usage_result("findings must be a list of strings")}

      {:ok, _} ->
        {:error, usage_result("findings must be a non-empty list of strings")}

      {:error, %{reason: reason}} ->
        {:error, usage_result(reason)}
    end
  end

  defp load_findings(nil), do: {:error, usage_result("--findings is required")}

  defp usage_result(message) do
    Result.error("kiln", :denied, errors: [Result.to_error(message)], exit_code: 2)
  end

  # -- command: candidate-invocation --
  #
  # Reads the request file specified by --request, validates it against
  # the canonical Candidate Invocation schema (P02-D013) without
  # dispatching to the provider, and gates production mode on the
  # presence of MINIMAX_API_KEY. The CLI surface is bounded:
  #   - evaluation mode: schema-valid dispatch proof, no network,
  #     no credential requirement;
  #   - production mode: requires MINIMAX_API_KEY; absence is a bounded
  #     :unavailable error mapped to exit 8 (per ErrorMap).
  # The CLI never opens a Store, writes a Journal, or runs Workflow.
  # KILN-M0-01 (E4) public consumer-visible surface; the live provider
  # dispatch (if/when invoked by other tooling) routes through the
  # adapter module directly, not through this CLI command.

  defp run_candidate_invocation(%Request{} = request) do
    request
    |> dispatch_candidate_invocation()
    |> normalize_dispatch_result(request)
  end

  defp dispatch_candidate_invocation(%Request{options: opts}) do
    request_path = opts["request"]
    mode = opts["mode"]

    with {:ok, attrs} <- Kiln.CandidateInvocationLoader.load(request_path),
         {:ok, %Kiln.CandidateInvocation{} = invocation} <-
           Kiln.CandidateInvocation.new_request(attrs),
         :ok <- gate_candidate_invocation_mode(mode) do
      {:ok,
       Result.ok("candidate-invocation",
         data: %{
           "schema_valid" => true,
           "mode" => mode,
           "invocation_id" => invocation.invocation_id,
           "semantic_digest" => invocation.semantic_digest,
           "adapter_implementation_digest" =>
             Kiln.MinimaxM3Adapter.implementation_digest()
         }
       )}
    else
      {:error, %Result{} = result} ->
        {:error, result}

      {:error, %{result_kind: _} = loader_error} ->
        {:error,
         Result.error("candidate-invocation", :denied,
           errors: [
             Result.to_error(%{
               code: :invalid_request,
               message: loader_error.reason,
               class: "invalid_request",
               details: Map.delete(loader_error, :reason)
             })
           ]
         )}

      {:error, reason} ->
        {:error,
         Result.error("candidate-invocation", :denied,
           errors: [Result.to_error(normalize_candidate_invocation_error(reason))]
         )}
    end
  end

  # `Kiln.CandidateInvocation.new_request/1` returns bounded 3-tuple and
  # 2-tuple errors (e.g. `{:invalid_field, :mode_atom, "PRODUCTION"}`).
  # The CLI error envelope expects a structured map; this pass converts
  # the bounded shape into the canonical error map before handing it to
  # `Result.to_error/1`. The two clauses are exhaustive over the
  # validation helpers in `Kiln.CandidateInvocation`; if a new shape ever
  # lands upstream, the dispatch's `{:error, reason}` pattern fail-fast
  # surfaces it loudly rather than silently emitting a generic error.
  defp normalize_candidate_invocation_error({:invalid_field, field, value}) do
    %{
      code: :invalid_field,
      message: "invalid field #{inspect(field)}: #{inspect(value)}",
      class: "invalid_request",
      details: %{field: field, value: value}
    }
  end

  defp normalize_candidate_invocation_error({:missing_field, field}) do
    %{
      code: :missing_field,
      message: "missing field #{inspect(field)}",
      class: "invalid_request",
      details: %{field: field}
    }
  end

  defp gate_candidate_invocation_mode("evaluation"), do: :ok

  defp gate_candidate_invocation_mode("production") do
    if System.get_env("MINIMAX_API_KEY") in [nil, ""] do
      {:error,
       Result.error("candidate-invocation", :blocked,
         exit_code: 8,
         errors: [
           Result.to_error(%{
             code: :unavailable,
             message:
               "production mode requires MINIMAX_API_KEY (presence-only, not value); CLI gates before any provider call"
           })
         ]
       )}
    else
      :ok
    end
  end

  defp gate_candidate_invocation_mode(other) do
    {:error,
     Result.error("candidate-invocation", :denied,
       errors: [
         Result.to_error("--mode must be one of: production|evaluation (got #{inspect(other)})")
       ]
     )}
  end

  defp run_writable(%Request{} = request, fun) do
    run_with_mode(request, :write, fun)
  end

  defp run_readonly(%Request{} = request, fun) do
    run_with_mode(request, :read, fun)
  end

  defp run_with_mode(%Request{} = request, mode, fun) do
    case Runtime.open(request.kiln_home, mode) do
      {:ok, :ready} ->
        try do
          request
          |> then(&fun.(&1, nil))
          |> normalize_dispatch_result(request)
        after
          Runtime.stop()
        end

      {:absent} ->
        absent_result(request)

      {:blocked, state, _error} ->
        blocked_result(request, state)
    end
  end

  # The supervise command opens the store in write mode because the
  # supervisor persists Artifacts, Evidence, and a supervision_runs row.
  # The dispatcher never reaches into Evidence or Artifact internals;
  # it routes through `Kiln.Supervision` only.
  defp run_supervise(%Request{} = request) do
    case Runtime.open(request.kiln_home, :write) do
      {:ok, :ready} ->
        try do
          request
          |> dispatch_supervise()
          |> normalize_dispatch_result(request)
        after
          Runtime.stop()
        end

      {:absent} ->
        absent_result(request)

      {:blocked, state, _error} ->
        blocked_result(request, state)
    end
  end

  defp normalize_dispatch_result({:ok, %Result{} = result}, _request),
    do: {result, result.exit_code}

  defp normalize_dispatch_result({:error, %Result{} = result}, _request),
    do: {result, result.exit_code}

  defp normalize_dispatch_result({:error, %Error{} = error}, request),
    do: error_result_tuple(request, error)

  defp normalize_dispatch_result({:ok, %Result{} = result, _session}, _request),
    do: {result, result.exit_code}

  defp normalize_dispatch_result({%Result{} = result, exit_code}, _request)
       when is_integer(exit_code),
       do: {result, exit_code}

  defp absent_result(%Request{command: command}) do
    {result, exit_code} =
      result_for_code(
        command,
        :no_session,
        "no state DB exists at --kiln-home; start one with `mix kiln start`"
      )

    {result, exit_code}
  end

  defp blocked_result(%Request{command: command}, state) do
    message =
      case state do
        :migration_blocked ->
          "migration is blocked; preserve files and follow the diagnostic action"

        :integrity_blocked ->
          "the store is corrupt; preserve files and run a manual recovery"

        :version_blocked ->
          "the binary cannot open this store; use a compatible Kiln"

        :unavailable ->
          "the store could not be opened"

        _ ->
          "the store could not be opened"
      end

    {status, exit_code} = ErrorMap.map(state)
    errors = [Result.to_error(%{code: state, message: message, class: "store_blocked"})]

    result =
      Result.error(atom_to_command(command), status,
        exit_code: exit_code,
        errors: errors
      )

    {result, exit_code}
  end

  # -- command: start --
  #
  # The CLI never constructs a Domain Session/Task/Run directly. It builds
  # the input shapes that `Kiln.Workflow.start_session/1` accepts and lets
  # the Workflow own journal writes, idempotency, request digests, and
  # state validation.

  defp dispatch_start(%Request{options: opts, actor_id: actor_id} = _request, _session) do
    with :ok <- precheck_no_session(),
         {:ok, workflow_input} <- build_start_workflow_input(opts, actor_id) do
      case workflow_input do
        %Result{} = result ->
          {:ok, result}

        workflow_opts when is_map(workflow_opts) ->
          case Workflow.start_session(workflow_opts) do
            {:ok, started} ->
              case capability_next_actions(started.session_id) do
                {:ok, mutating_actions} ->
                  {:ok,
                   Result.ok("start",
                     data: %{
                       session_id: started.session_id,
                       task_id: started.task_id,
                       root_run_id: started.run_id,
                       objective: workflow_opts[:objective] || workflow_opts["objective"]
                     },
                     session_revision: started.session_revision,
                     journal_digest: format_digest(started.projection_digest),
                     next_actions: navigation_actions("start") ++ mutating_actions
                   )}

                {:error, %Error{} = error} ->
                  {:error, error}
              end

            {:error, %Error{} = error} ->
              {:error, error}
          end
      end
    else
      {:error, %Result{} = result} -> {:error, result}
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  # Sequential one-Session guard. Returns `:ok` when no Session exists so
  # the caller can proceed, or `{:error, %Result{}}` carrying the blocked
  # CLI result when a Session already exists. The control-flow convention
  # `:ok | {:error, %Result{}}` is chosen so a `with` clause using the
  # `:ok` head short-circuits on the existing-Session case before any
  # durable input shaping, validation, or Workflow call runs; this is
  # what stops a second `mix kiln start` from creating a second Session.
  # A Workflow error during the lookup is returned as `{:error, %Error{}}`
  # so the upstream dispatcher surfaces it through the standard mapping.
  defp precheck_no_session do
    case Workflow.current_session() do
      {:ok, :empty} ->
        :ok

      {:ok, %{session_id: session_id}} ->
        {:error,
         Result.error("start", :blocked,
           errors: [
             Result.to_error(%{
               code: :session_already_exists,
               message:
                 "a Session already exists (#{session_id}); inspect or cancel it instead of starting another"
             })
           ]
         )}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp build_start_workflow_input(opts, actor_id) do
    case validate_command_options(opts) do
      :ok ->
        repo = opts["repo"]
        observation = build_project_observation(repo)

        {:ok,
         %{
           actor_id: actor_id,
           objective: opts["objective"],
           criteria: opts["criterion"],
           constraints: opts["constraint"] || [],
           exclusions: opts["exclude"] || [],
           project_observation: observation
         }}

      {:error, message} when is_binary(message) ->
        {:ok,
         Result.error("start", :denied,
           exit_code: 2,
           errors: [Result.to_error(message)]
         )}
    end
  end

  defp validate_command_options(opts) do
    cond do
      not non_empty?(opts["repo"]) ->
        {:error, "--repo is required"}

      not non_empty?(opts["objective"]) ->
        {:error, "--objective is required"}

      not non_empty_list?(opts["criterion"]) ->
        {:error, "at least one --criterion is required"}

      not optional_list?(opts["constraint"]) ->
        {:error, "every --constraint must be a non-empty string"}

      not optional_list?(opts["exclude"]) ->
        {:error, "every --exclude must be a non-empty string"}

      true ->
        :ok
    end
  end

  defp build_project_observation(repo_root) do
    fingerprint =
      "sha256:" <>
        (:crypto.hash(:sha256, repo_root) |> Base.encode16(case: :lower))

    %{
      repository_root: repo_root,
      repository_fingerprint: fingerprint,
      observed_at: DateTime.utc_now()
    }
  end

  # -- command: status --
  #
  # Status reads the current projection through `Workflow.current_session/0`
  # and never reaches into the projection, restart, or replay modules
  # directly.

  defp dispatch_status(%Request{} = _request, _session) do
    case Workflow.current_session() do
      {:ok, :empty} ->
        {:ok, no_session_result("status")}

      {:ok, %{projection: projection, session_id: session_id} = result} ->
        case capability_next_actions(session_id) do
          {:ok, mutating_actions} ->
            {:ok, status_result("status", projection, result, mutating: mutating_actions)}

          {:error, %Error{} = error} ->
            {:error, error}
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp status_result(command, projection, result, opts) do
    base_opts = [
      data: status_data(projection, result),
      session_revision: revision_from_projection(projection),
      journal_digest: format_digest(result.projection_digest),
      next_actions: status_next_actions(projection, result, Keyword.fetch!(opts, :mutating))
    ]

    if result.orphaned do
      Result.error(command, :unknown,
        exit_code: 7,
        errors: [
          Result.to_error(%{
            code: :orphaned_run,
            message: "the Run has an unresolved external effect and requires reconciliation"
          })
        ],
        data: base_opts[:data],
        session_revision: base_opts[:session_revision],
        journal_digest: base_opts[:journal_digest],
        next_actions: base_opts[:next_actions]
      )
    else
      Result.ok(command, base_opts)
    end
  end

  defp status_data(projection, result) do
    %{
      session_id: get_in(projection, ["session", "id"]),
      session_state: get_in(projection, ["session", "state"]),
      task_id: get_in(projection, ["task", "id"]),
      task_state: get_in(projection, ["task", "state"]),
      root_run_id: get_in(projection, ["run", "id"]),
      run_state: effective_run_state(projection, result),
      workflow_step: projection["workflow_step"],
      pending_decision: summarize_pending_decision(projection["pending_decision"]),
      operation: summarize_operation(effective_operation(projection, result)),
      cache_status: to_string(result.source),
      orphaned: result.orphaned,
      journal_head: format_digest(result.journal_head_digest)
    }
  end

  # Status emits `inspect` as the navigation suggestion; the Workflow-owned
  # mutating capability set is appended unchanged. The orphan / pending-
  # decision / active-operation branches emit only navigation suggestions
  # because the Workflow capability matrix returns `[]` for those states.
  defp status_next_actions(projection, result, mutating_actions) do
    base =
      cond do
        result.orphaned ->
          [
            Result.next_action(
              "inspect",
              "review the unknown operation and orphan markers"
            )
          ]

        get_in(projection, ["pending_decision"]) != nil ->
          [
            Result.next_action("inspect", "review the pending decision")
          ]

        get_in(projection, ["operation"]) != nil ->
          [
            Result.next_action("inspect", "review the active external operation")
          ]

        true ->
          [Result.next_action("inspect", "review the current state")]
      end

    base ++ mutating_actions
  end

  # -- command: inspect --
  #
  # Inspect renders the full accepted P1-S01 state from the Workflow
  # query result. The renderer-facing fields are sourced from the
  # projection map; the Workflow query exposes them only through the
  # authoritative load_projection path.

  defp dispatch_inspect(%Request{} = _request, _session) do
    case Workflow.current_session() do
      {:ok, :empty} ->
        {:ok, no_session_result("inspect")}

      {:ok, %{projection: projection, session_id: session_id} = result} ->
        case capability_next_actions(session_id) do
          {:ok, mutating_actions} ->
            {:ok, inspect_result("inspect", projection, result, mutating: mutating_actions)}

          {:error, %Error{} = error} ->
            {:error, error}
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp inspect_result(command, projection, result, opts) do
    data = inspect_data(projection, result)
    mutating_actions = Keyword.fetch!(opts, :mutating)

    base_opts = [
      data: data,
      session_revision: revision_from_projection(projection),
      journal_digest: format_digest(result.projection_digest),
      next_actions: navigation_actions("inspect") ++ mutating_actions
    ]

    if result.orphaned do
      Result.error(command, :unknown,
        exit_code: 7,
        errors: [
          Result.to_error(%{
            code: :orphaned_run,
            message: "the Run has an unresolved external effect and requires reconciliation"
          })
        ],
        data: data,
        session_revision: base_opts[:session_revision],
        journal_digest: base_opts[:journal_digest],
        next_actions: base_opts[:next_actions]
      )
    else
      Result.ok(command, base_opts)
    end
  end

  defp inspect_data(projection, result) do
    unknowns = effective_unknowns(projection, result)

    %{
      session_id: get_in(projection, ["session", "id"]),
      session_state: get_in(projection, ["session", "state"]),
      task_id: get_in(projection, ["task", "id"]),
      task_state: get_in(projection, ["task", "state"]),
      root_run_id: get_in(projection, ["run", "id"]),
      run_state: effective_run_state(projection, result),
      workflow_step: projection["workflow_step"],
      objective_revision: projection["objective_revision"] || 0,
      criteria_revision: projection["criteria_revision"] || 0,
      objective: projection["objective"] || "",
      criteria: projection["criteria"] || [],
      constraints: projection["constraints"] || [],
      exclusions: projection["exclusions"] || [],
      pending_decision: summarize_pending_decision(projection["pending_decision"]),
      operation: summarize_operation(effective_operation(projection, result)),
      unknowns: unknowns,
      project_observation_id: get_in(projection, ["references", "project_observation_id"]),
      journal_head_digest: format_digest(result.journal_head_digest),
      projection_digest: result.projection_digest
    }
  end

  defp effective_unknowns(projection, %{orphaned: true}) do
    case projection["operation"] do
      %{"id" => id, "state" => state} when is_binary(id) and is_binary(state) ->
        if state in @nonterminal_operation_states do
          [%{"operation_id" => id, "reason" => "nonterminal_state"}]
        else
          projection["unknowns"] || []
        end

      _ ->
        projection["unknowns"] || []
    end
  end

  defp effective_unknowns(projection, _result), do: projection["unknowns"] || []

  # -- command: cancel --
  #
  # Cancel reads the current session through `current_session/0`, picks
  # up the session_id and run_state, and dispatches the mutation through
  # `Workflow.cancel_session/2`. The CLI never builds a journal action
  # envelope directly.

  defp dispatch_cancel(%Request{options: opts, actor_id: actor_id} = request, _session) do
    case Workflow.current_session() do
      {:ok, :empty} ->
        {:ok, no_session_result("cancel")}

      {:ok, %{projection: projection} = _current} ->
        session_id = get_in(projection, ["session", "id"])
        task_id = get_in(projection, ["task", "id"])
        run_id = get_in(projection, ["run", "id"])
        previous_run_state = get_in(projection, ["run", "state"])
        expected_revision = revision_from_projection(projection)

        with :ok <- terminal_check(previous_run_state, "cancel"),
             :ok <- active_operation_check(projection) do
          cancel_session_via_workflow(
            request,
            session_id,
            task_id,
            run_id,
            previous_run_state,
            expected_revision,
            actor_id,
            opts
          )
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp cancel_session_via_workflow(
         request,
         session_id,
         task_id,
         run_id,
         previous_run_state,
         expected_revision,
         actor_id,
         opts
       ) do
    case Workflow.cancel_session(session_id,
           actor_id: actor_id,
           expected_session_revision: expected_revision
         ) do
      {:ok, canceled} ->
        # Cancel transitions the Run to `:canceled`, a terminal Run state.
        # `Workflow.valid_next_actions/1` therefore advertises `[]` for the
        # post-cancel Session; the cancel result contains only navigation
        # suggestions (`status`, `inspect`) and never advertises `cancel`
        # or `resume` even when the Workflow capability matrix would later
        # be misconfigured, because the cancel result is constructed
        # without consulting that matrix at all.
        {:ok,
         Result.ok("cancel",
           data: %{
             session_id: session_id,
             task_id: task_id,
             root_run_id: run_id,
             previous_run_state: previous_run_state,
             run_state: "canceled"
           },
           session_revision: canceled.session_revision,
           journal_digest: format_digest(canceled.projection_digest),
           next_actions: navigation_actions("cancel")
         )}

      {:error, %Error{code: :run_transition_not_allowed} = error} ->
        # The Workflow returns :run_transition_not_allowed from terminal
        # states and from active operation. The CLI surfaces the terminal
        # case as :failed exit 6 with the legacy "already <state>" message
        # so the existing test contract holds.
        case Map.get(request.options, "reason") do
          _ ->
            {:error,
             error_for_terminal_cancel(
               previous_run_state,
               error,
               opts
             )}
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp error_for_terminal_cancel(previous_run_state, _workflow_error, _opts) do
    cli_native_error_result("cancel", :terminal_run_state, %{
      from: previous_run_state
    })
  end

  # -- command: resume --
  #
  # Resume is guidance-only per T04-R07. It reads the current projection
  # through `Workflow.current_session/0` and reports the Workflow's
  # `valid_next_actions/1` set as bounded next-action suggestions. It
  # performs no mutation; no journal write, no action commit, no
  # projection rebuild is performed by this command.

  defp dispatch_resume(%Request{} = _request, _session) do
    case Workflow.current_session() do
      {:ok, :empty} ->
        {:ok, no_session_result("resume")}

      {:ok, %{projection: projection} = result} ->
        session_id = get_in(projection, ["session", "id"])

        case capability_next_actions(session_id) do
          {:ok, mutating_actions} ->
            {:ok, resume_report_result(projection, result, mutating: mutating_actions)}

          {:error, %Error{} = error} ->
            {:error, error}
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp resume_report_result(projection, result, opts) do
    mutating_actions = Keyword.fetch!(opts, :mutating)

    data = %{
      session_id: get_in(projection, ["session", "id"]),
      task_id: get_in(projection, ["task", "id"]),
      root_run_id: get_in(projection, ["run", "id"]),
      session_state: get_in(projection, ["session", "state"]),
      task_state: get_in(projection, ["task", "state"]),
      run_state: effective_run_state(projection, result),
      workflow_step: projection["workflow_step"],
      next_actions: resume_next_actions(result, mutating_actions)
    }

    if result.orphaned do
      Result.error("resume", :unknown,
        exit_code: 7,
        errors: [
          Result.to_error(%{
            code: :orphaned_run,
            message: "the Run has an unresolved external effect and requires reconciliation"
          })
        ],
        data: data,
        session_revision: revision_from_projection(projection),
        journal_digest: format_digest(result.projection_digest),
        next_actions: data.next_actions
      )
    else
      Result.ok("resume",
        data: data,
        session_revision: revision_from_projection(projection),
        journal_digest: format_digest(result.projection_digest),
        next_actions: data.next_actions
      )
    end
  end

  defp resume_next_actions(result, mutating_actions) do
    base =
      if result.orphaned do
        [Result.next_action("inspect", "review the unknown operation and orphan markers")]
      else
        [Result.next_action("inspect", "review the current state")]
      end

    Enum.uniq(base ++ mutating_actions)
  end

  # -- error mapping --

  defp error_result_tuple(%Request{command: command}, %Error{} = error) do
    {status, exit_code} = ErrorMap.map(error.code)

    result =
      Result.error(atom_to_command(command), status,
        exit_code: exit_code,
        errors: [Result.to_error(error)]
      )

    {result, exit_code}
  end

  # Build a CLI-owned `Result` for an internal guard code. The CLI never
  # constructs `%Kiln.Domain.Error{}` directly; it picks a CLI-native code
  # atom that the ErrorMap already maps to a `{status, exit_code}` pair.
  defp cli_native_error_result(command, code, details) do
    {status, exit_code} = ErrorMap.map(code)

    Result.error(atom_to_command(command), status,
      exit_code: exit_code,
      errors: [
        Result.to_error(%{code: code, message: message_for(code, details), details: details})
      ]
    )
  end

  defp message_for(:terminal_run_state, %{from: from}),
    do: "Run is already #{from}; cancel is not allowed from a terminal state"

  defp message_for(:active_operation, _),
    do: "Run owns an active or unknown operation; resolve it before canceling"

  defp message_for(code, _details), do: Atom.to_string(code)

  defp result_for_code(command, code, message) do
    {status, exit_code} = ErrorMap.map(code)

    result =
      Result.error(atom_to_command(command), status,
        exit_code: exit_code,
        errors: [Result.to_error(%{code: code, message: message, class: "blocked"})]
      )

    {result, exit_code}
  end

  # Returns a plain `%Result{}` (no `{:ok, _}` tag) so the caller owns
  # the success-tag wrapping. This avoids the nested-`{:ok, {:ok, ...}}`
  # shape that previously broke `run_with_mode/3` for the initialized-
  # but-empty DB case (a write-mode CLI command that creates the store
  # but fails input validation, leaving a populated empty DB that a
  # subsequent read-only command hits).
  defp no_session_result(command) do
    Result.error(command, :blocked,
      errors: [
        Result.to_error(%{
          code: :no_session,
          message: "no Session exists; start one with `mix kiln start`"
        })
      ]
    )
  end

  # -- terminal-state guard for cancel --
  #
  # The Workflow returns :run_transition_not_allowed from a `:canceled`
  # Run state, but the original CLI contract required a `:failed` exit 6
  # with "already <state>" message. The CLI checks the projection's
  # Run state here and short-circuits with the legacy error before
  # calling the Workflow so the existing test contract holds.

  defp terminal_check(previous_run_state, command) do
    if previous_run_state in ["canceled", "completed", "failed"] do
      {:error, cli_native_error_result(command, :terminal_run_state, %{from: previous_run_state})}
    else
      :ok
    end
  end

  # -- active-operation guard for cancel --
  #
  # The original CLI refused to cancel a Run that owned an active or unknown
  # operation. The Workflow agreed semantically but rejected the cancel via
  # :run_transition_not_allowed, which the CLI surfaced as :blocked exit 4.
  # The dispatcher checks the raw projection here so the original error
  # message reaches the user before any Workflow call.

  defp active_operation_check(projection) do
    if projection["operation"] != nil do
      {:error, cli_native_error_result("cancel", :active_operation, %{})}
    else
      :ok
    end
  end

  # -- helpers --

  defp summarize_pending_decision(nil), do: nil
  defp summarize_pending_decision(decision), do: decision

  defp summarize_operation(nil), do: nil

  defp summarize_operation(operation) do
    %{
      "id" => operation["id"],
      "class" => operation["class"],
      "state" => operation["state"]
    }
  end

  defp revision_from_projection(projection) do
    projection["session_revision"] || projection["objective_revision"] || 0
  end

  defp format_digest(nil), do: nil
  defp format_digest("sha256:" <> _ = digest), do: digest
  defp format_digest(digest) when is_binary(digest), do: "sha256:" <> digest

  # Single source of truth for capability-driven `next_actions` output.
  # The CLI never invents a `cancel` or `resume` suggestion: it consults the
  # Workflow capability matrix via `Workflow.valid_next_actions/1` and
  # translates the bounded atoms the Workflow advertises into
  # `Result.next_action` values through `translate_capability/1`. The
  # mapping table below is the only place those atoms are turned into CLI
  # strings, so a future Workflow capability that the CLI does not
  # recognise is silently dropped rather than invented as a mutation. The
  # terminal-state contract is therefore enforced both at the Workflow
  # boundary (its capability matrix returns `[]`) and at the CLI boundary
  # (no mapped atom ever reaches the renderer).
  defp capability_next_actions(session_id) when is_binary(session_id) do
    case Workflow.valid_next_actions(session_id) do
      {:ok, actions} ->
        {:ok,
         actions
         |> Enum.map(&translate_capability/1)
         |> Enum.reject(&is_nil/1)}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  # Maps Workflow application capability atoms to T04 CLI executable
  # mutations. The mapping is intentionally narrow: T04 exposes exactly
  # one executable CLI mutation, `cancel`, which performs
  # `Workflow.cancel_session/2`. T04 `resume` is guidance-only per R07;
  # mapping `:resume_session -> "resume"` would tell the user to execute
  # a command that does not perform `Workflow.resume_session/2`. The
  # `:resume_session` atom is therefore not translated into a CLI
  # next-action; the user can still invoke `mix kiln resume` directly
  # for guidance, but it is not advertised as a Workflow-authorized
  # executable mutation.
  defp translate_capability(:cancel_session),
    do: Result.next_action("cancel", "cancel the Session explicitly")

  defp translate_capability(_other_application_atom), do: nil

  # Presentation/navigation suggestions the CLI may emit independently
  # because they describe how to navigate the CLI surface rather than how
  # to mutate application state. `cancel` and `resume` are deliberately
  # absent — they must always come from `capability_next_actions/1`.
  defp navigation_actions("start") do
    [
      Result.next_action("status", "show the current projection"),
      Result.next_action("inspect", "show the complete accepted state")
    ]
  end

  defp navigation_actions("status") do
    []
  end

  defp navigation_actions("inspect") do
    [Result.next_action("status", "show the current projection")]
  end

  defp navigation_actions("cancel") do
    [
      Result.next_action("status", "show the canceled state"),
      Result.next_action("inspect", "show the complete accepted state")
    ]
  end

  defp navigation_actions("resume") do
    [Result.next_action("inspect", "show the complete accepted state")]
  end

  defp navigation_actions("supervise") do
    [
      Result.next_action("inspect", "review the durable Run Result Envelope"),
      Result.next_action("status", "show the current projection")
    ]
  end

  defp navigation_actions("worker-propose") do
    [
      Result.next_action("patch-decide", "review the worker output and emit a patch decision")
    ]
  end

  defp navigation_actions("patch-decide") do
    [
      Result.next_action("patch-apply", "apply the approved exact bytes"),
      Result.next_action("worker-propose", "produce a new worker output")
    ]
  end

  defp navigation_actions("patch-apply") do
    [
      Result.next_action("patch-recover", "if the run died between mutation and evidence, run recovery"),
      Result.next_action("status", "show the current projection")
    ]
  end

  defp navigation_actions("patch-recover") do
    [
      Result.next_action("status", "show the current projection")
    ]
  end

  defp navigation_actions("verify-run") do
    [
      Result.next_action("review-propose", "produce the independent Reviewer Review"),
      Result.next_action("status", "show the current projection")
    ]
  end

  defp navigation_actions("review-propose") do
    [
      Result.next_action("human-decide", "record the final human decision"),
      Result.next_action("status", "show the current projection")
    ]
  end

  defp navigation_actions("human-decide") do
    [
      Result.next_action("status", "show the current Run Result Projection")
    ]
  end

  # The Workflow exposes `orphaned: true` when the persisted projection
  # carries a non-nil operation in a nonterminal state. The persisted
  # `run.state` does not change to "orphaned" until Restart rebuilds
  # the projection; here we apply the same classification to the
  # renderer-facing fields so the CLI matches the legacy contract
  # (`run_state: "orphaned"`, `operation.state: "unknown"`).

  defp effective_run_state(projection, %{orphaned: true}) do
    case projection["operation"] do
      %{} -> "orphaned"
      _ -> get_in(projection, ["run", "state"])
    end
  end

  defp effective_run_state(projection, _result) do
    get_in(projection, ["run", "state"])
  end

  defp effective_operation(projection, %{orphaned: true}) do
    case projection["operation"] do
      %{"state" => state} = op when is_binary(state) ->
        if state in @nonterminal_operation_states do
          Map.put(op, "state", "unknown")
        else
          op
        end

      _ ->
        projection["operation"]
    end
  end

  defp effective_operation(projection, _result), do: projection["operation"]

  defp non_empty?(nil), do: false
  defp non_empty?(value) when is_binary(value), do: byte_size(value) > 0
  defp non_empty?(_), do: false

  defp non_empty_list?(nil), do: false
  defp non_empty_list?(values) when is_list(values), do: Enum.all?(values, &non_empty?/1)
  defp non_empty_list?(_), do: false

  defp optional_list?(nil), do: true

  defp optional_list?(values) when is_list(values),
    do: Enum.all?(values, &non_empty?/1)

  defp optional_list?(_), do: true

  defp atom_to_command(nil), do: "kiln"
  defp atom_to_command(command) when is_atom(command), do: Atom.to_string(command)
  defp atom_to_command(command), do: command

  # -- help / version --

  defp help_result do
    Result.ok("help",
      data: %{
        usage:
          "mix kiln [--format text|json] [--kiln-home PATH] [--actor-id ID] <command> [options]",
        commands: command_summary(),
        global_options: [
          %{flag: "--format", description: "output format: text (default) or json"},
          %{flag: "--kiln-home", description: "local KILN_HOME path containing state.sqlite3"},
          %{flag: "--actor-id", description: "actor identifier (required; or set KILN_ACTOR_ID)"},
          %{flag: "--help", description: "show this summary"},
          %{flag: "--version", description: "show the development version"}
        ],
        notes: [
          "This is a source-development entry point. The packaged release is not yet shipped.",
          "Provider, Context, Repository read, Patch, Command, completion, Receipt, Child, and TUI behavior are not exposed."
        ]
      },
      next_actions:
        Enum.map(@supported_commands, fn command ->
          Result.next_action(
            Atom.to_string(command),
            "run the #{Atom.to_string(command)} command"
          )
        end)
    )
  end

  defp version_result do
    Result.ok("version", data: %{version: @version, schema: Result.schema()})
  end

  defp command_summary do
    Enum.map(@supported_commands, fn command ->
      %{
        command: Atom.to_string(command),
        description: description_for(command)
      }
    end)
  end

  defp description_for(:start), do: "start one durable Session, Task, and ready Root Run"
  defp description_for(:status), do: "show the current projection and safe next actions"
  defp description_for(:inspect), do: "show the complete accepted P1-S01 state"
  defp description_for(:cancel), do: "cancel the Run when no operation is open or unknown"
  defp description_for(:resume), do: "report the current projection and valid next actions"

  defp description_for(:supervise),
    do: "supervise one Repository Recon Work Envelope through Kiln.Supervision"

  defp description_for(:worker_propose),
    do:
      "(M8) one bounded IMPLEMENTER attempt: validate Intelligence Assignment + qualification at dispatch, observe repository, emit canonical worker-output/m0-v1"

  defp description_for(:patch_decide),
    do:
      "(M8) record an explicit canonical human patch decision (APPROVE_EXACT_BYTES / REJECT / REQUEST_REVISION) against the proposal"

  defp description_for(:patch_apply),
    do:
      "(M8) apply the exact approved bytes after APPROVE_EXACT_BYTES and emit canonical patch-application-evidence/m0-v1"

  defp description_for(:patch_recover),
    do:
      "(M8) recover a non-terminal M8 state when observed_state_digest matches expected post-state; refuse to repair an unknown repository state"

  defp description_for(:verify_run),
    do:
      "(M9) execute a registered verifier against the post-mutation state and emit canonical verification-result/m0-v1"

  defp description_for(:review_propose),
    do:
      "(M9) bounded REVIEWER dispatch via independently assigned Reviewer Assignment; emits canonical review/m0-v1 with implementer_transcript_received: false"

  defp description_for(:human_decide),
    do:
      "(M9) record an explicit canonical human decision (ACCEPT|REJECT|REQUEST_REVISION); emit human-decision/m0-v1 and run-result-projection/m0-v1"

  # -- command: supervise --
  #
  # The Wave 3 supervision boundary. Accepts a Work Envelope payload
  # path through `--work-envelope`, validates the payload through
  # `Kiln.WorkEnvelope.new/1`, observes the target repository, decides
  # `git.read` authority through `Kiln.Authority`, persists Artifact +
  # Evidence through the merged substrate, and produces the run-result
  # envelope. The CLI never reaches into Evidence or Artifact
  # internals; it routes through `Kiln.Supervision` only.
  defp dispatch_supervise(%Request{options: opts, actor_id: actor_id} = request) do
    work_envelope_path = Map.fetch!(opts, "work-envelope")

    with {:ok, attrs} <- Kiln.WorkEnvelopeLoader.load(work_envelope_path),
         {:ok, store} <- ready_store(request) do
      completion = Map.get(opts, "observation-completion", default_completion())

      supervise_opts = [
        store: store,
        actor_id: actor_id,
        now: now_iso(),
        git: Map.get(opts, "git", "git"),
        observation_completion: completion
      ]

      supervision_result =
        if get_in(attrs, ["capability", "id"]) == "verify-change" do
          case Map.get(opts, "verification-change") do
            path when is_binary(path) and path != "" ->
              with {:ok, verification_attrs} <- Kiln.WorkEnvelopeLoader.load(path) do
                Kiln.Verification.Supervision.supervise(
                  attrs,
                  verification_attrs,
                  supervise_opts
                )
              end

            _ ->
              {:error, :verification_change_required}
          end
        else
          Kiln.Supervision.supervise(attrs, supervise_opts)
        end

      case supervision_result do
        {:ok, %Kiln.RunResultEnvelope{} = envelope} ->
          result_map = Kiln.RunResultEnvelope.to_map(envelope)

          {:ok,
           Result.ok("supervise",
             data: %{
               run_id: envelope.run_id,
               work_id: envelope.work_id,
               status: Atom.to_string(envelope.status),
               acceptance_readiness: envelope.acceptance_readiness,
               envelope: result_map
             },
             session_revision: 0,
             journal_digest: nil,
             next_actions: navigation_actions("supervise")
           )}

        {:error, {:idempotency_conflict, _, _}} ->
          idempotency_conflict_result()

        {:error, reason} ->
          supervise_error_result(reason)
      end
    else
      {:error, %Error{} = error} ->
        error_result_tuple(request, error)

      {:error, reason} ->
        code = error_code(reason)
        {status, exit_code} = ErrorMap.map(code)
        errors = [Result.to_error(%{code: code, message: inspect(reason)})]
        {Result.error("supervise", status, exit_code: exit_code, errors: errors), exit_code}
    end
  end

  # The CLI opens the supervised store through `Kiln.CLI.Runtime` in
  # write mode (the supervisor persists Artifacts, Evidence, and a
  # `supervision_runs` row). After startup, `Kiln.Store.Connection` is
  # registered with the live `conn`. The store map handed to the
  # supervisor must satisfy the Artifact substrate's expected shape
  # (`%{conn: pid, artifact_root: path}`) or `Artifact.Store.put/2`
  # raises `FunctionClauseError`.
  #
  # The canonical Artifact root is derived from the same `state.sqlite3`
  # path Runtime opened via `Kiln.Store.artifact_root_for_path/1`. This
  # helper is the single source of truth for the path layout; Runtime,
  # `Kiln.Store.start/1`, and this dispatcher all derive the same
  # directory. The CLI does not invent a second artifact location
  # convention.
  defp ready_store(%Request{kiln_home: kiln_home}) do
    with pid when is_pid(pid) <- Process.whereis(Kiln.Store.Connection) do
      state_path = Path.join(kiln_home, "state.sqlite3")
      artifact_root = Kiln.Store.artifact_root_for_path(state_path)
      {:ok, %{conn: pid, artifact_root: artifact_root}}
    else
      _ -> {:error, :store_unavailable}
    end
  end

  # The Wave 3 wedge does not embed the Loadout procedure; the producer
  # supplies its observation completion through the Work Envelope or
  # through a deterministic fixture. This default returns a successful
  # completion so the CLI runs the full happy-path pipeline without a
  # separate orchestrator process.
  defp default_completion do
    %{
      status: :completed,
      warnings: [],
      unknowns: []
    }
  end

  defp now_iso, do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp idempotency_conflict_result do
    {status, exit_code} = ErrorMap.map(:idempotency_conflict)

    result =
      Result.error("supervise", status,
        exit_code: exit_code,
        errors: [
          Result.to_error(%{
            code: :idempotency_conflict,
            message: "the same work_id was used with a materially different request"
          })
        ]
      )

    {result, exit_code}
  end

  defp supervise_error_result(reason) do
    code = error_code(reason)
    {status, exit_code} = ErrorMap.map(code)

    result =
      Result.error("supervise", status,
        exit_code: exit_code,
        errors: [Result.to_error(reason)]
      )

    {result, exit_code}
  end

  defp error_code(%Kiln.Store.Error{code: code}), do: code
  defp error_code(%{code: code}) when is_atom(code), do: code
  defp error_code(_), do: :unknown
end
