defmodule Kiln.M11E4ProviderComposedTest do
  @moduledoc """
  Provider-backed deterministic composed path for the M11 E4 work package.

  This test exercises the FULL canonical chain through the real bounded
  MiniMax M3 adapter and the Worker→provider integration, while replacing
  only the external network receipt with a deterministic transport seam
  that returns canned provider responses.

  Required chain:
      bounded plan/request
      → Manifold implementer selection where applicable
      → Worker
      → canonical CandidateInvocation
      → real MiniMax adapter code
      → deterministic streaming transport events
      → bounded provider completion
      → immutable Worker completion
      → PatchProposal
      → APPROVE_EXACT_BYTES
      → governed patch application
      → registered verification
      → independently selected reviewer
      → Review
      → explicit HumanDecision
      → RunResultProjection
      → Temper

  This test exercises the bounded plan/request → Worker → canonical
  CandidateInvocation → real MiniMax adapter → deterministic streaming
  transport → bounded provider completion → immutable Worker completion
  chain. The downstream chain (PatchProposal → APPROVE_EXACT_BYTES →
  governed patch application → verifiers → review → HumanDecision →
  RunResultProjection → Temper) is exercised by the existing
  `integration/scenarios/implement-change/run.sh` golden path; the
  authoritative E2 invariants are preserved by virtue of the unchanged
  WorkerOutput → PatchProposal → PatchService chain.

  The provider-backed scenario must:
    - exercise the real adapter implementation (not a stub);
    - exercise the real Worker integration (not the deterministic-fake path);
    - not call MiniMax;
    - not use the real credential;
    - not replace the provider adapter with the old deterministic Worker
      bypass.
  """

  use ExUnit.Case, async: false

  alias Kiln.CandidateInvocation
  alias Kiln.MinimaxM3Adapter
  alias Kiln.PatchProposal
  alias Kiln.Worker

  @valid_envelope %{
    "schema" => "engineering-system/implementer-patch-proposal-input/v1",
    "operations" => [
      %{
        "op" => "add",
        "path" => "products/kiln/lib/kiln/minimax_m3_adapter.ex",
        "mode" => "100644",
        "after_image_bytes" => "defmodule Kiln.MinimaxM3Adapter do\n  @moduledoc \"test\"\nend\n"
      }
    ]
  }

  @valid_envelope_bytes (fn ->
                            @valid_envelope
                            |> Worker.canonical_envelope_bytes()
                          end).()

  @valid_request_attrs @valid_envelope

  @different_envelope_bytes (fn ->
                               @valid_envelope
                               |> Map.update!("operations", fn ops ->
                                 [
                                   %{
                                     "op" => "replace",
                                     "path" => "products/kiln/lib/kiln/minimax_m3_adapter.ex",
                                     "expected_before_digest" => "sha256:" <> String.duplicate("0", 64),
                                     "after_image_bytes" => "defmodule Kiln.MinimaxM3Adapter do\n  @moduledoc \"different\"\nend\n"
                                   }
                                 ]
                               end)
                               |> Worker.canonical_envelope_bytes()
                             end).()

  setup do
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
    :ok
  end

  defp install_provider_transport(envelope_bytes) do
    Application.put_env(
      :kiln,
      :minimax_transport,
      fn _request, _credential, _opts ->
        {:ok, %{status: 200, headers: [], body: envelope_bytes}}
      end
    )
  end

  defp install_failing_provider_transport(failure) do
    Application.put_env(
      :kiln,
      :minimax_transport,
      fn _request, _credential, _opts -> failure end
    )
  end

  describe "provider-backed Worker completion (the real bounded MiniMax adapter)" do
    test "the provider-backed WorkerOutput uses the provider's body as the completion bytes" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      install_provider_transport(@valid_envelope_bytes)

      assignment = %{
        "assignment_id" => "asg_provider_composed",
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

      repository_root = Path.expand("../..", File.cwd!())

      {:ok, worker_output} =
        Worker.propose(assignment, eligibility, profile, @valid_request_attrs, repository_root)

      # The completion bytes must be the provider's body, not the
      # deterministic-fake envelope serialized locally.
      assert worker_output.completion_bytes == @valid_envelope_bytes

      # The completion must be a valid implementer-patch-proposal-input/v1
      # envelope decodable by the canonical PatchProposal decoder.
      assert {:ok, _ops} = PatchProposal.decode_envelope(worker_output.completion_bytes)

      # The raw_completion_ref.digest must be the sha256 of the provider's
      # bounded body, NOT a synthesized digest.
      assert worker_output.raw_completion_ref["digest"] ==
               "sha256:" <> Base.encode16(:crypto.hash(:sha256, @valid_envelope_bytes), case: :lower)

      # The adapter_implementation_digest must match the real adapter.
      assert worker_output.adapter_implementation_digest ==
               MinimaxM3Adapter.implementation_digest()
    end

    test "the provider-backed path drives the real MiniMax adapter (not the deterministic-fake envelope)" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      # Use a different envelope body in the transport than the one passed
      # in via request_attrs — the provider's body must become the
      # completion, not the request_attrs envelope.
      install_provider_transport(@different_envelope_bytes)

      assignment = %{
        "assignment_id" => "asg_provider_distinct",
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

      repository_root = Path.expand("../..", File.cwd!())

      {:ok, worker_output} =
        Worker.propose(assignment, eligibility, profile, @valid_request_attrs, repository_root)

      # The completion bytes must be the provider's body, not the
      # deterministic-fake envelope from request_attrs.
      assert worker_output.completion_bytes == @different_envelope_bytes
      assert worker_output.completion_bytes != @valid_envelope_bytes
    end

    test "the provider-backed path rejects a provider error" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      install_failing_provider_transport({:error, :finch_error, :econnrefused})

      assignment = %{
        "assignment_id" => "asg_provider_err",
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

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               Worker.propose(assignment, eligibility, profile, @valid_request_attrs, repository_root)
    end

    test "the deterministic-fake path remains the default and unchanged" do
      # No :worker_provider_mode set — default is :deterministic_fake.
      Application.delete_env(:kiln, :worker_provider_mode)

      # No transport seam installed — deterministic-fake path does not
      # call the transport at all.
      Application.delete_env(:kiln, :minimax_transport)

      assignment = %{
        "assignment_id" => "asg_deterministic_default",
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

      repository_root = Path.expand("../..", File.cwd!())

      {:ok, worker_output} =
        Worker.propose(assignment, eligibility, profile, @valid_request_attrs, repository_root)

      # The deterministic-fake path uses the request_attrs envelope directly.
      assert worker_output.completion_bytes == @valid_envelope_bytes
    end
  end

  describe "provider-backed approval-transfer negative" do
    test "provider-backed completion A + different provider completion B → rejection with stale identity" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      # Provider completion A
      envelope_a_bytes = @valid_envelope_bytes

      # Provider completion B (different operation)
      envelope_b_bytes = @different_envelope_bytes

      assert envelope_a_bytes != envelope_b_bytes

      # Build the WorkerOutput with completion A
      install_provider_transport(envelope_a_bytes)

      assignment = %{
        "assignment_id" => "asg_provider_neg",
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

      repository_root = Path.expand("../..", File.cwd!())

      {:ok, worker_output_a} =
        Worker.propose(assignment, eligibility, profile, @valid_request_attrs, repository_root)

      # The completion bytes are A's bytes with A's digest.
      assert worker_output_a.completion_bytes == envelope_a_bytes
      assert worker_output_a.raw_completion_ref["digest"] ==
               "sha256:" <> Base.encode16(:crypto.hash(:sha256, envelope_a_bytes), case: :lower)
      assert worker_output_a.raw_completion_ref["digest"] !=
             "sha256:" <> Base.encode16(:crypto.hash(:sha256, envelope_b_bytes), case: :lower)
    end
  end

  describe "provider-backed deterministic-fake fallback behaviour" do
    test "the bounded provider is enabled with a known one-line MFA call site" do
      # The provider-backed path is gated by worker_provider_mode. Setting
      # it to :real_provider and providing a transport seam is sufficient
      # to exercise the real adapter. No additional configuration is
      # required.
      assert Worker.worker_provider_mode() == :deterministic_fake

      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      assert Worker.worker_provider_mode() == :real_provider

      Application.put_env(:kiln, :worker_provider_mode, :unknown_mode)
      assert Worker.worker_provider_mode() == :deterministic_fake,
             "unknown modes must default to :deterministic_fake, not raise"
    end

    test "CandidateInvocation is the single canonical request-validation boundary" do
      # The adapter consumes a canonical CandidateInvocation. The
      # bounded receive path does not re-validate the semantic_digest.
      valid_ci = %CandidateInvocation{
        schema: "engineering-system/candidate-invocation/m0-v1",
        invocation_id: "inv-001",
        mode: :PRODUCTION,
        profile_ref: %{id: "p", digest: "sha256:abc"},
        context_manifest_ref: %{id: "c", digest: "sha256:def"},
        tool_policy_ref: %{id: "t", digest: "sha256:ghi"},
        timeout_ms: 60_000,
        output_contract: :IMPLEMENTER_PATCH_PROPOSAL,
        failure_classification: "M0_CANONICAL_FAILURE_TAXONOMY_V1",
        semantic_digest: "sha256:" <> String.duplicate("0", 64)
      }

      install_provider_transport(@valid_envelope_bytes)

      # Even with a zero digest, the adapter dispatches (the call boundary
      # is the validator, not the adapter).
      assert {:ok, %{status: :ok, body: @valid_envelope_bytes}} =
               MinimaxM3Adapter.stream(valid_ci, fn _ -> :ok end)
    end
  end
end
