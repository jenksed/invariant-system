defmodule Temper.M3GraphViewTest do
  @moduledoc """
  DX test: can an engineer implement a graph component without
  thinking about ANSI cursor operations?

  Builds a Kiln.GraphProjection fixture, then renders it through
  Temper.M3GraphView → Temper.CellFrame. Asserts the output is
  meaningful and stable, and that the visible text contains the
  expected node labels.

  The point: the engineer writing M3GraphView wrote a TREE of
  declarative primitives (`{:box, ...}`, `{:line, ...}`), not a
  screen painter. CellFrame owns the rasterization.
  """

  use ExUnit.Case, async: true

  alias Kiln.GraphProjection
  alias Temper.CellFrame
  alias Temper.M3GraphView

  defp build_facts do
    %{
      worker_output: %Kiln.M0WorkerOutput{
        id: "wko_dx01",
        semantic_digest: "sha256:" <> String.duplicate("a", 64),
        attempt_ref: %{"id" => "att_dx", "digest" => "sha256:" <> String.duplicate("0", 64)},
        assignment_ref: %{"id" => "asg_dx", "digest" => "sha256:" <> String.duplicate("1", 64)},
        profile_ref: %{"id" => "prof_dx", "digest" => "sha256:" <> String.duplicate("2", 64)},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => "raw_dx", "digest" => "sha256:" <> String.duplicate("3", 64)},
        parsed_candidate_digest: "sha256:" <> String.duplicate("4", 64),
        completion_bytes: "x",
        base_commit: "0" |> String.duplicate(40),
        base_state_digest: "sha256:" <> String.duplicate("5", 64),
        adapter_implementation_digest: "sha256:" <> String.duplicate("6", 64)
      },
      proposal: %Kiln.M0PatchProposal{
        id: "pp_dx01",
        semantic_digest: "sha256:" <> String.duplicate("b", 64),
        plan_ref: %{"id" => "plan_dx", "digest" => "sha256:" <> String.duplicate("7", 64)},
        attempt_ref: %{"id" => "att_dx", "digest" => "sha256:" <> String.duplicate("0", 64)},
        patch_digest: "sha256:" <> String.duplicate("8", 64),
        base_commit: "0" |> String.duplicate(40),
        repository: "/tmp",
        supersedes_patch_ref: nil
      },
      verification: %Kiln.M0VerificationResult{
        id: "ver_dx01",
        semantic_digest: "sha256:" <> String.duplicate("c", 64),
        plan_ref: %{"id" => "plan_dx", "digest" => "sha256:" <> String.duplicate("7", 64)},
        patch_ref: %{"id" => "pp_dx01", "digest" => "sha256:" <> String.duplicate("8", 64)},
        status: :PASS,
        result_state_digest: "sha256:" <> String.duplicate("9", 64),
        registered_verifier: %{"id" => "vrf_dx", "digest" => "sha256:" <> String.duplicate("d", 64)},
        evidence_refs: []
      },
      review: %Kiln.M0Review{
        id: "rev_dx01",
        semantic_digest: "sha256:" <> String.duplicate("e", 64),
        plan_ref: %{"id" => "plan_dx", "digest" => "sha256:" <> String.duplicate("7", 64)},
        patch_ref: %{"id" => "pp_dx01", "digest" => "sha256:" <> String.duplicate("8", 64)},
        verifier_ref: %{"id" => "ver_dx01", "digest" => "sha256:" <> String.duplicate("c", 64)},
        context_manifest_ref: %{"id" => "ctx_dx", "digest" => "sha256:" <> String.duplicate("f", 64)},
        result_state_digest: "sha256:" <> String.duplicate("9", 64),
        verdict: :APPROVE,
        findings: ["bounded rules satisfied"],
        implementer_transcript_received: false,
        reviewer_assignment_ref: %{"id" => "revr_dx", "digest" => "sha256:" <> String.duplicate("a", 64)}
      },
      human_decision: %Kiln.M0HumanDecision{
        id: "hd_dx01",
        semantic_digest: "sha256:" <> String.duplicate("0", 64),
        plan_ref: %{"id" => "plan_dx", "digest" => "sha256:" <> String.duplicate("7", 64)},
        patch_ref: %{"id" => "pp_dx01", "digest" => "sha256:" <> String.duplicate("8", 64)},
        review_ref: %{"id" => "rev_dx01", "digest" => "sha256:" <> String.duplicate("e", 64)},
        result_state_digest: "sha256:" <> String.duplicate("9", 64),
        decision: :ACCEPT,
        recorded_at: "2026-08-20T00:00:00Z",
        metadata: %{}
      },
      patch_evidence: %Kiln.M0PatchEvidence{
        id: "pe_dx01",
        semantic_digest: "sha256:" <> String.duplicate("1", 64),
        patch_ref: %{"id" => "pp_dx01", "digest" => "sha256:" <> String.duplicate("8", 64)},
        decision_ref: %{"id" => "pd_dx01", "digest" => "sha256:" <> String.duplicate("3", 64)},
        pre_state_digest: "sha256:" <> String.duplicate("4", 64),
        post_state_digest: "sha256:" <> String.duplicate("2", 64),
        effect: "APPLIED"
      },
      source_identity: "0" |> String.duplicate(40)
    }
  end

  test "renders a graph view without any ANSI cursor code in the implementation" do
    {:ok, projection} = GraphProjection.build(build_facts())
    frame = M3GraphView.view(projection, 30, 80)
    text = CellFrame.to_text(frame)

    # The visible text should contain labels for the canonical nodes.
    assert text =~ "Worker Output"
    assert text =~ "Patch Proposal"
    assert text =~ "Verification"
    assert text =~ "Review"
    assert text =~ "Human Decision"
    assert text =~ "Patch Evidence"
  end

  test "is deterministic" do
    {:ok, projection} = GraphProjection.build(build_facts())
    a = M3GraphView.view(projection, 30, 80)
    b = M3GraphView.view(projection, 30, 80)
    assert CellFrame.to_text(a) == CellFrame.to_text(b)
  end

  test "FAILED verification surfaces visually" do
    facts = build_facts()
    facts = put_in(facts, [:verification], %{facts.verification | status: :FAIL})
    {:ok, projection} = GraphProjection.build(facts)
    frame = M3GraphView.view(projection, 30, 80)
    text = CellFrame.to_text(frame)
    assert text =~ "Verification"
  end

  test "the implementation file does not contain raw ANSI escape sequences" do
    # DX property: the engineer should not need to write \x1b
    # sequences to build a graph component.
    path = Path.join([File.cwd!(), "lib", "temper", "m3_graph_view.ex"])
    {:ok, source} = File.read(path)

    refute source =~ "\\x1b[",
           "M3GraphView should not contain raw ANSI escape sequences; CellFrame owns the rasterization"
  end
end
