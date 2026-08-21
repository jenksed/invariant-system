defmodule InvariantImplementChangeScenarioHelper do
  @moduledoc false

  def main(["materialize-proposal", kiln_home, proof_repo, worker_output_path, proposal_path]) do
    {:ok, _} = Application.ensure_all_started(:kiln)
    {:ok, :ready} = Kiln.CLI.Runtime.open(kiln_home, :read)

    try do
      conn = Process.whereis(Kiln.Store.Connection)
      state_path = Path.join(kiln_home, "state.sqlite3")
      artifact_root = Kiln.Store.artifact_root_for_path(state_path)
      store = %{conn: conn, artifact_root: artifact_root}

      wo_map = worker_output_path |> File.read!() |> JSON.decode!()
      raw_ref = wo_map["raw_completion_ref"]

      # Retrieve the immutable bounded completion from Artifact.Store. The
      # store verifies sha256(retrieved)==ref.digest before returning bytes.
      {:ok, completion_bytes, %{integrity_status: :verified}} =
        Kiln.Artifact.Store.read(store, raw_ref["id"])

      # The completion is the implementer-patch-proposal-input/v1 envelope.
      {:ok, ops_with_bytes} = Kiln.PatchProposal.decode_envelope(completion_bytes)

      worker_output_struct = %Kiln.M0WorkerOutput{
        id: wo_map["id"],
        semantic_digest: wo_map["semantic_digest"],
        attempt_ref: wo_map["attempt_ref"],
        assignment_ref: wo_map["assignment_ref"],
        profile_ref: wo_map["profile_ref"],
        output_kind: wo_map["output_kind"] || "PATCH_CANDIDATE",
        raw_completion_ref: raw_ref,
        parsed_candidate_digest: wo_map["parsed_candidate_digest"],
        completion_bytes: completion_bytes,
        base_commit: wo_map["base_commit"] || "",
        base_state_digest: wo_map["base_state_digest"],
        adapter_implementation_digest:
          wo_map["adapter_implementation_digest"] || "sha256:" <> String.duplicate("0", 64)
      }

      plan_ref = %{
        "id" => "pln_e2_scenario",
        "digest" => "sha256:" <> String.duplicate("6", 64)
      }

      {:ok, proposal} =
        Kiln.PatchProposal.build_from_worker_output(
          worker_output_struct,
          ops_with_bytes,
          plan_ref,
          proof_repo
        )

      File.write!(proposal_path, JSON.encode!(Map.from_struct(proposal)))
    after
      Kiln.CLI.Runtime.stop()
    end
  end

  def main(["run-verifier", proof_repo, base_commit, verifier_output]) do
    {:ok, _} = Application.ensure_all_started(:kiln)

    command = %{
      "command_id" => "repo.diff-check",
      "executable" => "git",
      "argv" => ["diff", "--check", base_commit, "--"],
      "working_directory" => ".",
      "environment_policy" => "minimal-toolchain-path",
      "network_policy" => "not-required",
      "mutation_expectation" => "none",
      "timeout_ms" => 30_000,
      "proves" => ["patch_did_not_introduce_whitespace_errors"]
    }

    {:ok, validated} = Kiln.Verification.Registry.validate(command, proof_repo, base_commit)
    {:ok, result} = Kiln.Verification.CommandHost.run(validated)
    File.write!(verifier_output, JSON.encode!(result))
  end

  def main([
        "build-projection",
        evidence_path,
        verification_path,
        review_path,
        human_decision_path,
        plan_ref_path,
        impl_assign_ref_path,
        revr_assign_ref_path,
        patch_ref_path,
        verification_ref_path,
        review_ref_path,
        projection_path
      ]) do
    evidence = evidence_path |> File.read!() |> JSON.decode!()
    _verification = verification_path |> File.read!() |> JSON.decode!()
    review = review_path |> File.read!() |> JSON.decode!()
    hd = human_decision_path |> File.read!() |> JSON.decode!()

    plan_ref = plan_ref_path |> File.read!() |> JSON.decode!()
    impl_assign_ref = impl_assign_ref_path |> File.read!() |> JSON.decode!()
    revr_assign_ref = revr_assign_ref_path |> File.read!() |> JSON.decode!()
    patch_ref = patch_ref_path |> File.read!() |> JSON.decode!()
    verification_ref = verification_ref_path |> File.read!() |> JSON.decode!()
    review_ref = review_ref_path |> File.read!() |> JSON.decode!()

    # Preserve the existing M11 scenario reference construction exactly. The
    # scenario is qualifying current behavior, not redefining domain semantics.
    patch_decision_ref = %{
      "id" => hd["id"],
      "digest" => hd["semantic_digest"]
    }

    human_decision_ref = %{
      "id" => hd["id"],
      "digest" => hd["semantic_digest"]
    }

    truth_status = %{
      "run_status" =>
        if(evidence["effect"] == "EXACT_TARGET_STATE_OBSERVED", do: "completed", else: "failed"),
      "verification_status" => "PASS",
      "review_status" => review["verdict"],
      "human_status" => "ACCEPT",
      "unknown_effects" => []
    }

    refs = %{
      "plan_ref" => plan_ref,
      "implementer_assignment_ref" => impl_assign_ref,
      "reviewer_assignment_ref" => revr_assign_ref,
      "patch_ref" => patch_ref,
      "patch_decision_ref" => patch_decision_ref,
      "verification_ref" => verification_ref,
      "review_ref" => review_ref,
      "human_decision_ref" => human_decision_ref,
      "run_result_ref" => plan_ref,
      "truth" => truth_status
    }

    {:ok, projection} = Kiln.RunResultProjection.build(refs)
    File.write!(projection_path, JSON.encode!(Kiln.M0RunResultProjection.to_map(projection)))
  end

  def main(args) do
    raise ArgumentError,
          "unsupported implement-change scenario helper invocation: #{inspect(args)}"
  end
end

InvariantImplementChangeScenarioHelper.main(System.argv())
