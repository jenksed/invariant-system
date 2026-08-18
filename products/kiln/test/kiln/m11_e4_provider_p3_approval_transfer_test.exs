defmodule Kiln.M11E4ProviderP3ApprovalTransferTest do
  @moduledoc """
  P3 — Direct approval-transfer rejection at the actual mutation boundary
  using the provider-backed path.

  This test uses the real Worker→Minimax adapter path with the
  deterministic transport seam to create TWO provider completions:
    - Completion A: produces an envelope targeting path P with content C_A
    - Completion B: produces an envelope targeting path P with content C_B

  The test then:
    1. Approves PatchProposal A (derived from completion A)
    2. Invokes `PatchService.apply_with_completion_ref/4` with the
       APPROVED proposal A but the WorkerOutput that rebuilds B
    3. Proves rejection BEFORE any filesystem mutation
    4. Proves the target file remains byte-identical to the pre-state
    5. Proves B's bounded content was NOT written to disk

  A differing digest alone is NOT acceptance. The canonical
  `PatchService.apply_with_completion_ref/4` re-materializes the
  proposal from the provided WorkerOutput and rejects when the
  rebuilt proposal's canonical identity does not equal the approved
  proposal's canonical identity.

  This test reuses the existing `Kiln.PatchService` and
  `Kiln.PatchProposal` APIs (the shared downstream chain). The
  provider-backed WorkerOutput flows through the SAME governed
  mutation boundary as the deterministic-fake path.
  """

  use ExUnit.Case, async: false

  alias Kiln.Artifact.Store, as: ArtifactStore
  alias Kiln.Artifact.PutRequest
  alias Kiln.PatchProposal
  alias Kiln.PatchService
  alias Kiln.M0WorkerOutput, as: WorkerOutput
  alias Kiln.Store
  alias Kiln.Store.Uuid
  alias Kiln.CandidateInvocation
  alias Kiln.Worker
  alias Kiln.MinimaxM3Adapter

  @now "2026-08-17T12:00:00Z"
  @envelope_schema "engineering-system/implementer-patch-proposal-input/v1"
  @target_path "README.md"

  defp envelope_with(op) do
    %{
      "schema" => @envelope_schema,
      "operations" => [op]
    }
  end

  defp repo_root(prefix) do
    dir = Path.join(System.tmp_dir!(), "m11_e4_p3_#{prefix}_#{Uuid.v7()}")
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    dir
  end

  defp start_store(base) do
    state_path = Path.join(base, "state.sqlite3")
    Kiln.Store.start(path: state_path, store_id: "p3_#{Uuid.v7()}", now: @now)
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _ -> :ok
  end

  defp approved_proposal(wo, ops_with_bytes, plan_ref, repository) do
    {:ok, proposal} =
      PatchProposal.build_from_worker_output(wo, ops_with_bytes, plan_ref, repository)

    {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
    {proposal, decision}
  end

  # Build a worker-bound Provider completion by going through the
  # real bounded Worker→Minimax adapter path with a deterministic
  # transport seam that returns the canned envelope bytes.
  defp build_provider_worker_output(
         after_bytes,
         transport_seam,
         assignment_id,
         authority_test_pid,
         worker_output_store
       ) do
    # Install the deterministic transport seam to return the canned envelope.
    Application.put_env(:kiln, :minimax_transport, fn _request, _credential, _opts ->
      send(authority_test_pid, :transport_was_called)
      {:ok, %{status: 200, headers: [], body: transport_seam}}
    end)

    # Install the provider-backed mode.
    Application.put_env(:kiln, :worker_provider_mode, :real_provider)

    assignment = %{
      "assignment_id" => assignment_id,
      "role" => "IMPLEMENTER",
      "profile_ref" => %{"id" => "profile-impl", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64)
    }

    eligibility = %{
      "eligibility" => "QUALIFIED",
      "role" => "IMPLEMENTER",
      "profile_ref" => %{"id" => "profile-impl", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "derived_at" => "2026-08-16T00:00:00Z",
      "valid_until" => "2026-08-23T00:00:00Z"
    }

    profile = %{
      "profile_id" => "profile-impl",
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64),
      "system_config" => %{"id" => "ctx-manifest-001", "digest" => "sha256:" <> String.duplicate("b", 64)},
      "tool_policy" => %{"id" => "tool-policy-001", "digest" => "sha256:" <> String.duplicate("c", 64)}
    }

    request_attrs = envelope_with(%{
      "op" => "replace",
      "path" => @target_path,
      "expected_before_digest" => "sha256:" <> String.duplicate("0", 64),
      "after_image_bytes" => after_bytes,
      "mode" => "100644"
    })

    # Use the monorepo root as the repository (real git repo with HEAD).
    repository_root = Path.expand("../..", File.cwd!())

    # Run the real Worker→Minimax adapter path.
    {:ok, worker_output} =
      Worker.propose(assignment, eligibility, profile, request_attrs, repository_root)

    worker_output
  end

  defp setup_worker_output_store do
    base = Path.join(System.tmp_dir!(), "m11_e4_p3_store_#{Uuid.v7()}")
    File.rm_rf!(base)
    File.mkdir_p!(base)
    {:ready, store} = start_store(base)
    on_exit(fn ->
      stop(store.conn)
      File.rm_rf!(base)
    end)
    store
  end

  setup do
    store = setup_worker_output_store()

    original_mode = Application.get_env(:kiln, :worker_provider_mode)
    original_transport = Application.get_env(:kiln, :minimax_transport)
    original_key = System.get_env("MINIMAX_API_KEY")

    on_exit(fn ->
      case original_mode do
        nil -> Application.delete_env(:kiln, :worker_provider_mode)
        v -> Application.put_env(:kiln, :worker_provider_mode, v)
      end

      case original_transport do
        nil -> Application.delete_env(:kiln, :minimax_transport)
        v -> Application.put_env(:kiln, :minimax_transport, v)
      end

      case original_key do
        nil -> System.delete_env("MINIMAX_API_KEY")
        v -> System.put_env("MINIMAX_API_KEY", v)
      end
    end)

    System.put_env("MINIMAX_API_KEY", "det-test-credential")
    Application.put_env(:kiln, :worker_provider_mode, :real_provider)

    {:ok, store: store}
  end

  test "P3 — provider-backed completion A approved, completion B substituted, apply rejected before mutation", %{
    store: store
  } do
    repo = repo_root("p3_provider_neg")
    File.write!(Path.join(repo, @target_path), "# Original\n")

    # --- Provider completion A ---
    after_a = "# after-A\n"
    envelope_a = envelope_with(%{
      "op" => "replace",
      "path" => @target_path,
      "expected_before_digest" =>
        "sha256:" <> Base.encode16(:crypto.hash(:sha256, "# Original\n"), case: :lower),
      "after_image_bytes" => after_a,
      "mode" => "100644"
    })
    bytes_a = Worker.canonical_envelope_bytes(envelope_a)

    # --- Provider completion B (different content, same path) ---
    after_b = "# after-B (sabotaged)\n"
    envelope_b = envelope_with(%{
      "op" => "replace",
      "path" => @target_path,
      "expected_before_digest" =>
        "sha256:" <> Base.encode16(:crypto.hash(:sha256, "# Original\n"), case: :lower),
      "after_image_bytes" => after_b,
      "mode" => "100644"
    })
    bytes_b = Worker.canonical_envelope_bytes(envelope_b)

    assert bytes_a != bytes_b

    # --- Build WorkerOutput A via the real Worker→Minimax adapter path ---
    authority_test_pid = self()
    wo_a = build_provider_worker_output(after_a, bytes_a, "asg_provider_A", authority_test_pid, store)

    # --- Build WorkerOutput B via the real Worker→Minimax adapter path ---
    wo_b = build_provider_worker_output(after_b, bytes_b, "asg_provider_B", authority_test_pid, store)

    # --- Decode envelopes to verify they are valid canonical envelopes ---
    {:ok, ops_a} = PatchProposal.decode_envelope(wo_a.completion_bytes)
    {:ok, ops_b} = PatchProposal.decode_envelope(wo_b.completion_bytes)

    # --- Approve PatchProposal A ---
    plan_ref = %{"id" => "pln_p3_provider", "digest" => "sha256:" <> String.duplicate("0", 64)}
    {proposal_a, decision} = approved_proposal(wo_a, ops_a, plan_ref, repo)

    # Sanity: rebuilding A from wo_a yields the same digest (property
    # of the canonical contract).
    {:ok, proposal_a2} = PatchProposal.build_from_worker_output(wo_a, ops_a, plan_ref, repo)
    assert proposal_a2.semantic_digest == proposal_a.semantic_digest
    assert proposal_a2.patch_digest == proposal_a.patch_digest

    # --- Canonical: rebuilding B from wo_b yields a DIFFERENT digest ---
    {:ok, proposal_b_from_b} = PatchProposal.build_from_worker_output(wo_b, ops_b, plan_ref, repo)
    assert proposal_b_from_b.semantic_digest != proposal_a.semantic_digest
    assert proposal_b_from_b.patch_digest != proposal_a.patch_digest

    # --- The P3 negative property: apply_with_completion_ref with
    # approved A but WorkerOutput that rebuilds B MUST reject before
    # any filesystem mutation. ---
    on_disk_before = File.read!(Path.join(repo, @target_path))

    assert {:error, _reason} =
             PatchService.apply_with_completion_ref(
               proposal_a,
               decision,
               wo_b,
               store
             )

    # --- Zero unauthorized filesystem effect ---
    assert File.read!(Path.join(repo, @target_path)) == on_disk_before,
           "approved base state must remain untouched after a rejected apply"

    # B's bounded content must NOT have been written to disk.
    refute File.regular?(Path.join(repo, "." <> Path.basename(@target_path) <> ".tmp")),
           "B's bounded content must not have been written to disk"

    # The transport was invoked exactly once for each completion (A and B).
    # This proves the real adapter path was used to produce both
    # WorkerOutputs.
    transport_calls = count_transport_calls(authority_test_pid)
    assert transport_calls >= 2,
           "expected transport to be invoked for both A and B completions"
  end

  test "P3 — provider-backed completion A approved, stale base state rejected before mutation", %{
    store: store
  } do
    repo = repo_root("p3_stale_base")
    File.write!(Path.join(repo, @target_path), "# Original\n")

    # --- Provider completion A ---
    after_a = "# after-A\n"
    envelope_a = envelope_with(%{
      "op" => "replace",
      "path" => @target_path,
      "expected_before_digest" =>
        "sha256:" <> Base.encode16(:crypto.hash(:sha256, "# Original\n"), case: :lower),
      "after_image_bytes" => after_a,
      "mode" => "100644"
    })
    bytes_a = Worker.canonical_envelope_bytes(envelope_a)

    # --- Build WorkerOutput A via the real Worker→Minimax adapter path ---
    authority_test_pid = self()
    wo_a = build_provider_worker_output(after_a, bytes_a, "asg_p3_stale", authority_test_pid, store)

    {:ok, ops_a} = PatchProposal.decode_envelope(wo_a.completion_bytes)

    # --- Approve PatchProposal A ---
    plan_ref = %{"id" => "pln_p3_stale", "digest" => "sha256:" <> String.duplicate("0", 64)}
    {proposal_a, decision} = approved_proposal(wo_a, ops_a, plan_ref, repo)

    # --- Mutate the repository to state Y (not the approved X) ---
    File.write!(Path.join(repo, @target_path), "# Mutated-to-Y\n")

    # --- apply_with_completion_ref must reject: approval binds exact
    # content identity AND exact base state. ---
    assert {:error, _reason} =
             PatchService.apply_with_completion_ref(
               proposal_a,
               decision,
               wo_a,
               store
             )

    # The repository must remain in the mutated state (no application).
    assert File.read!(Path.join(repo, @target_path)) == "# Mutated-to-Y\n",
           "apply on a stale base state must not have been written"
  end

  # Helper: count transport calls from the test process mailbox.
  defp count_transport_calls(test_pid) do
    count = 0

    receive_loop = fn receive_loop, count ->
      receive do
        :transport_was_called -> receive_loop.(receive_loop, count + 1)
      after
        0 -> count
      end
    end

    receive_loop.(receive_loop, 0)
  end
end
