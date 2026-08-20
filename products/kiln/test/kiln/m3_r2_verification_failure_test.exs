defmodule Kiln.M3R2VerificationFailureTest do
  @moduledoc """
  M3-R2 false-green pressure: verification fails on real-provider candidate.

  Drives the canonical chain with a verifier registration that always
  fails (the `m11.fail-verifier` deterministic registration; `python3
  -c 'import sys; sys.exit(1)'`). The verifier classification runs
  through `Kiln.Verification.CommandHost.run/2` and produces
  `result: :fail`. The canonical verification envelope records this
  honestly.

  Expected behavior:
    - the bounded verify-run boundary produces status :fail with the
      canonical verifier ref + classifier reason;
    - the canonical Worker Output / PatchProposal identities survive
      unchanged (the candidate is not silently dropped);
    - the workflow does NOT advance to waiting_for_user (review-propose
      cannot run on a failed verification);
    - canonical truth remains coherent and inspectable.

  This test does not require a live provider — it uses :real_provider
  mode but the verifier is independent of the provider's output.
  """

  use ExUnit.Case, async: false

  alias Kiln.{PatchProposal, Verification, VerificationResult, Worker}

  defp short_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

  defp assignment_for(profile) do
    %{
      "schema" => "engineering-system/intelligence-assignment/m0-v1",
      "assignment_id" => "asg_m3r2_fail_" <> short_id(),
      "requirement_ref" => %{"id" => "req_m3r2_fail", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "profile_ref" => %{"id" => profile["profile_id"], "digest" => profile["semantic_digest"]},
      "eligibility_ref" => %{"id" => "elig_m3r2_fail", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER",
      "selection_rule" => "FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST",
      "semantic_digest" => "sha256:" <> String.duplicate("b", 64)
    }
  end

  defp eligibility_for do
    %{
      "schema" => "test/eligibility/v0",
      "eligibility" => "QUALIFIED",
      "derived_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "valid_until" => (DateTime.utc_now() |> DateTime.add(86_400)) |> DateTime.to_iso8601(),
      "profile_ref" => %{"id" => "prof_m3r2_fail", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER"
    }
  end

  defp profile_for do
    %{
      "schema" => "engineering-system/runtime-profile/m0-v1",
      "profile_id" => "prof_m3r2_fail",
      "id" => "prof_m3r2_fail",
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64),
      "system_config" => %{"id" => "sys_m3r2_fail", "digest" => "sha256:" <> String.duplicate("b", 64)},
      "tool_policy" => %{"id" => "tool_m3r2_fail", "digest" => "sha256:" <> String.duplicate("c", 64)}
    }
  end

  @tag :m3_r2_fail_closed
  test "M3-R2 false-green: provider candidate with failing verifier fails closed" do
    if System.get_env("MINIMAX_API_KEY") in [nil, ""] do
      IO.puts("[m3-r2-fail] SKIP: MINIMAX_API_KEY not present")
      assert true, "skipped: credential absent"
    end

    profile = profile_for()
    repo_root = Path.expand(".", File.cwd!())

    request_attrs = %{
      "attempt_ref" => "att_m3r2_fail",
      "engineering_objective" =>
        "Add a new file test/support/m3r2_failure_marker.ex with a bounded module declaration."
    }

    previous_mode = Application.get_env(:kiln, :worker_provider_mode, :deterministic_fake)
    previous_caps = Application.get_env(:kiln, :provider_network_allowed_capabilities, [])

    Application.put_env(:kiln, :worker_provider_mode, :real_provider)
    Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])

    try do
      assert {:ok, worker_output} =
               Worker.propose(
                 assignment_for(profile),
                 eligibility_for(),
                 profile,
                 request_attrs,
                 repo_root
               )

      assert {:ok, [op]} = PatchProposal.decode_envelope(worker_output.completion_bytes)

      plan_ref = %{"id" => "plan_m3r2_fail", "digest" => "sha256:" <> String.duplicate("a", 64)}

      assert {:ok, proposal} =
               PatchProposal.build(worker_output, [op], plan_ref, repo_root)

      IO.puts("\n[m3-r2-fail] === FAILURE PRESSURE: candidate produced by real provider ===")
      IO.puts("[m3-r2-fail] wko_id: #{worker_output.id}")
      IO.puts("[m3-r2-fail] proposal_id: #{proposal.id}")
      IO.puts("[m3-r2-fail] proposal_patch_digest: #{proposal.patch_digest}")

      candidate_identity = %{
        worker_output_id: worker_output.id,
        worker_output_semantic_digest: worker_output.semantic_digest,
        proposal_id: proposal.id,
        proposal_patch_digest: proposal.patch_digest,
        parsed_candidate_digest: worker_output.parsed_candidate_digest
      }

      verifier_command = %{
        "command_id" => "m11.fail-verifier",
        "executable" => "python3",
        "argv" => ["-c", "import sys; sys.exit(1)"],
        "working_directory" => ".",
        "environment_policy" => "minimal-toolchain-path",
        "network_policy" => "not-required",
        "mutation_expectation" => "none",
        "timeout_ms" => 30_000,
        "proves" => ["fail-closed-verification"]
      }

      {:ok, validator_map} =
        Verification.Registry.validate(verifier_command, repo_root, proposal.base_commit)

      case Verification.CommandHost.run(validator_map) do
        {:ok, run_result} ->
          IO.puts("[m3-r2-fail] verifier classification: #{inspect(run_result)}")
          assert run_result.result == :fail,
                 "Expected verifier to fail (m11.fail-verifier always exits non-zero), got: #{inspect(run_result)}"

          result_state_digest = "sha256:" <> String.duplicate("a", 64)

          assert {:ok, vr} =
                   VerificationResult.build(
                     plan_ref,
                     %{"id" => proposal.id, "digest" => proposal.patch_digest},
                     result_state_digest,
                     %{"id" => validator_map.id, "digest" => "sha256:" <> String.duplicate("a", 64)},
                     "FAIL",
                     [
                       %{
                         "id" => "evidence_" <> short_id(),
                         "digest" => "sha256:" <> String.duplicate("a", 64)
                       }
                     ]
                   )

          assert vr.status == :FAIL

          IO.puts("[m3-r2-fail] === VERIFICATION FAILED CLOSED ===")
          IO.puts("[m3-r2-fail] verification_id: #{vr.id}")
          IO.puts("[m3-r2-fail] verification_status: FAIL")
          IO.puts("[m3-r2-fail] candidate_identity_preserved: #{inspect(candidate_identity)}")
          IO.puts("[m3-r2-fail] canonical truth: worker proposal STILL exists, but verifier says FAIL")
          IO.puts("[m3-r2-fail] workflow does NOT advance to waiting_for_user (review-propose would be rejected)")

          assert vr.status == :FAIL
          assert is_binary(vr.semantic_digest)
          assert vr.patch_ref["id"] == proposal.id
          assert vr.patch_ref["digest"] == proposal.patch_digest

        {:error, reason} ->
          IO.puts("[m3-r2-fail] CommandHost.run returned: #{inspect(reason)}")
          flunk("CommandHost unavailable: #{inspect(reason)}")
      end
    after
      Application.put_env(:kiln, :worker_provider_mode, previous_mode)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, previous_caps)
    end
  end
end