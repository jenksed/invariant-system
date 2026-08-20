defmodule Temper.M4SnapshotTest do
  @moduledoc """
  M4 — captures the actual rendered text for the five required
  visible states.

  Outputs are written to priv/m4_snapshots/ and printed to stdout
  so we can compare product behavior against the intended DX.
  """

  use ExUnit.Case, async: false

  alias Kiln.GraphProjection
  alias Temper.AttentionProjection
  alias Temper.{CellFrame, M4Inspector, M4ProofView, M4WorkMap}

  defp sha do
    "sha256:" <> String.duplicate("a", 64)
  end

  defp base_facts do
    %{
      worker_output: %Kiln.M0WorkerOutput{
        id: "wko_snap01",
        semantic_digest: sha(),
        attempt_ref: %{"id" => "att", "digest" => sha()},
        assignment_ref: %{"id" => "asg", "digest" => sha()},
        profile_ref: %{"id" => "prof", "digest" => sha()},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => "raw", "digest" => sha()},
        parsed_candidate_digest: sha(),
        completion_bytes: "{}",
        base_commit: String.duplicate("0", 40),
        base_state_digest: sha(),
        adapter_implementation_digest: sha()
      },
      proposal: %Kiln.M0PatchProposal{
        id: "pp_snap01",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        attempt_ref: %{"id" => "att", "digest" => sha()},
        patch_digest: sha(),
        base_commit: String.duplicate("0", 40),
        repository: "/tmp",
        supersedes_patch_ref: nil
      },
      verification: %Kiln.M0VerificationResult{
        id: "ver_snap01",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_snap01", "digest" => sha()},
        status: :PASS,
        result_state_digest: sha(),
        registered_verifier: %{"id" => "vrf", "digest" => sha()},
        evidence_refs: []
      },
      review: %Kiln.M0Review{
        id: "rev_snap01",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_snap01", "digest" => sha()},
        verifier_ref: %{"id" => "ver_snap01", "digest" => sha()},
        context_manifest_ref: %{"id" => "ctx", "digest" => sha()},
        result_state_digest: sha(),
        verdict: :APPROVE,
        findings: ["bounded rules satisfied"],
        implementer_transcript_received: false,
        reviewer_assignment_ref: %{"id" => "revr", "digest" => sha()}
      },
      human_decision: %Kiln.M0HumanDecision{
        id: "hd_snap01",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_snap01", "digest" => sha()},
        review_ref: %{"id" => "rev_snap01", "digest" => sha()},
        result_state_digest: sha(),
        decision: :ACCEPT,
        recorded_at: "2026-08-20T00:00:00Z",
        metadata: %{}
      },
      patch_evidence: %Kiln.M0PatchEvidence{
        id: "pe_snap01",
        semantic_digest: sha(),
        patch_ref: %{"id" => "pp_snap01", "digest" => sha()},
        decision_ref: %{"id" => "pd", "digest" => sha()},
        pre_state_digest: sha(),
        post_state_digest: sha(),
        effect: "APPLIED"
      },
      source_identity: String.duplicate("0", 40)
    }
  end

  defp render_text(state, rows, cols) do
    frame = M4WorkMap.render(state, rows, cols)
    CellFrame.to_text(frame)
  end

  defp write_snapshot(name, text) do
    dir = Path.join([File.cwd!(), "priv", "m4_snapshots"])
    File.mkdir_p!(dir)
    path = Path.join(dir, name <> ".txt")
    File.write!(path, text)
    IO.puts("\n=== #{name} ===")
    IO.puts(text)
    IO.puts("=== END #{name} (saved to #{path}) ===\n")
  end

  defp selected(state, id), do: %{state | selected_id: id}

  test "completed M3 lifecycle at 120x40" do
    {:ok, projection} = GraphProjection.build(base_facts())
    env = %{human_decision: :ACCEPTED, run_state: :ready, verification_status: :PASS}
    state = M4WorkMap.new(projection, "Improve reconnect clarity and add regression scenario for M2", env)
    text = render_text(state, 40, 120)
    write_snapshot("01_completed_120x40", text)

    assert text =~ "TEMPER"
    assert text =~ "GOVERNED"
    assert text =~ "0 need you"
  end

  test "human-decision-needed state at 120x40" do
    facts =
      base_facts()
      |> Map.delete(:human_decision)
      |> Map.delete(:patch_evidence)

    {:ok, projection} = GraphProjection.build(facts)
    env = %{run_state: :waiting_for_user, human_decision: :WAITING}
    state = M4WorkMap.new(projection, "Test the human-decision visual signal", env)
    text = render_text(state, 40, 120)
    write_snapshot("02_human_decision_needed_120x40", text)
    assert text =~ "TEMPER"
    assert text =~ "YOUR CALL"
  end

  test "failed verification state at 120x40" do
    facts = base_facts()
    facts = put_in(facts, [:verification], %{facts.verification | status: :FAIL})
    {:ok, projection} = GraphProjection.build(facts)
    env = %{verification_status: :FAIL, run_state: :failed}
    state = M4WorkMap.new(projection, "Test failed-verification visual signal", env)
    text = render_text(state, 40, 120)
    write_snapshot("03_failed_verification_120x40", text)
    assert text =~ "TEMPER"
    assert text =~ "Completion blocked"
  end

  test "provenance / Proof view" do
    {:ok, projection} = GraphProjection.build(base_facts())
    text =
      CellFrame.to_text(
        M4ProofView.render(projection, "pe_snap01", 30, 80)
      )

    write_snapshot("04_proof_view_80x30", text)
    assert text =~ "PROOF"
    assert text =~ "PatchEvidence"
    assert text =~ "Worker"
  end

  test "80x24 compact view" do
    {:ok, projection} = GraphProjection.build(base_facts())
    env = %{human_decision: :ACCEPTED, run_state: :ready}
    state = M4WorkMap.new(projection, "Compact narrow rendering must remain coherent", env)
    text = render_text(state, 24, 80)
    write_snapshot("05_compact_80x24", text)
    assert text =~ "TEMPER"
    assert text =~ "Worker"
  end
end
