defmodule Kiln.M0WorkerTest do
  @moduledoc """
  M8 KILN-M0-02 worker tests.

  Covers:
    * binding-validation positives (Assignment + Eligibility + Profile)
    * binding-validation negatives (E_PROFILE_REF_MISMATCH,
      E_QUALIFICATION_NOT_CURRENT, E_ROLE_MISMATCH)
    * bounded operation building
    * canonical-digest computation

  The Worker never mutates source. The Worker never authorizes its
  own patch. All tests are network-independent; the Worker emits a
  bounded envelope whose raw bytes are deterministic given the input.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  use ExUnit.Case, async: true

  alias Kiln.Worker
  alias Kiln.M0WorkerOutput, as: WorkerOutput

  # The implementation digest surfaced by `mix kiln
  # candidate-invocation-digest`. Computed from the runtime adapter
  # source; the value is bound by the production evidence and verified
  # by `test-m6-role-qualification.py` and `mix test` for Kiln.
  @runtime_adapter_digest Kiln.MinimaxM3Adapter.implementation_digest()

  # Canonical M6 IMPLEMENTER evidence produced by BENCH-M0-01. The
  # selector M7 verifies these digests; M8 revalidates at dispatch.
  @m6_implementer_profile_path Path.expand(
                                 "../../../../products/arsenal/evaluation/profiles/m0/implementer.json",
                                 __DIR__
                               )

  @m6_implementer_eligibility_path Path.expand(
                                     "../../../../products/arsenal/evaluation/qualifications/m0/implementer-eligibility.json",
                                     __DIR__
                                   )

  setup do
    profile = read_json(@m6_implementer_profile_path)
    eligibility = read_json(@m6_implementer_eligibility_path)
    %{profile: profile, eligibility: eligibility}
  end

  describe "binding validation (E2)" do
    test "valid binding succeeds", %{profile: profile, eligibility: eligibility} do
      assignment = build_assignment(profile, eligibility)

      assert {:ok, :validated} =
               Worker.validate_binding(profile, eligibility, assignment)
    end

    test "wrong role fails closed", %{profile: profile, eligibility: eligibility} do
      eligibility = put_in(eligibility, ["role"], "REVIEWER")
      assignment = build_assignment(profile, eligibility)

      assert {:error, %{code: :E_ROLE_MISMATCH}} =
               Worker.validate_binding(profile, eligibility, assignment)
    end

    test "stale eligibility fails closed", %{profile: profile, eligibility: eligibility} do
      stale = %{
        eligibility
        | "derived_at" => "2020-01-01T00:00:00Z",
          "valid_until" => "2020-01-08T00:00:00Z"
      }

      assignment = build_assignment(profile, stale)

      assert {:error, %{code: :E_QUALIFICATION_NOT_CURRENT}} =
               Worker.validate_binding(profile, stale, assignment)
    end

    test "qualification not QUALIFIED fails closed", %{profile: profile, eligibility: eligibility} do
      ineligible = put_in(eligibility, ["eligibility"], "NOT_ELIGIBLE")
      assignment = build_assignment(profile, ineligible)

      assert {:error, %{code: :E_QUALIFICATION_NOT_CURRENT}} =
               Worker.validate_binding(profile, ineligible, assignment)
    end

    test "profile digest mismatch fails closed", %{profile: profile, eligibility: eligibility} do
      tampered =
        put_in(eligibility, ["profile_ref", "digest"], "sha256:" <> String.duplicate("0", 64))

      assignment = build_assignment(profile, tampered)

      assert {:error, %{code: :E_PROFILE_REF_MISMATCH}} =
               Worker.validate_binding(profile, tampered, assignment)
    end
  end

  describe "bounded operation (E2)" do
    test "build_bounded_completion is deterministic", %{profile: _profile} do
      # M11 E2 B-repair: `build_bounded_completion/1` now accepts the
      # canonical `implementer-patch-proposal-input/v1` envelope
      # (the bounded patch content the Worker is proposing) and
      # serializes it. Same envelope → same bytes → same digest.
      envelope = %{
        "schema" => "engineering-system/implementer-patch-proposal-input/v1",
        "operations" => [
          %{
            "op" => "add",
            "path" => "README.md",
            "after_image_bytes" => "# hi\n"
          }
        ]
      }

      assert {:ok, bytes_a, digest_a} = Worker.build_bounded_completion(envelope)
      assert {:ok, bytes_b, digest_b} = Worker.build_bounded_completion(envelope)

      assert bytes_a == bytes_b
      assert digest_a == digest_b
      assert is_binary(bytes_a) and byte_size(bytes_a) > 0
      assert is_binary(digest_a) and String.starts_with?(digest_a, "sha256:")
    end
  end

  # -- helpers --

  defp build_assignment(profile, eligibility) do
    %{
      "schema" => "engineering-system/intelligence-assignment/m0-v1",
      "assignment_id" => "asg_test_" <> short_id(),
      "requirement_ref" => %{
        "id" => "req_test",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      },
      "profile_ref" => %{
        "id" => profile["profile_id"],
        "digest" => profile["semantic_digest"]
      },
      "eligibility_ref" => %{
        "id" => eligibility["eligibility_id"],
        "digest" => eligibility["semantic_digest"]
      },
      "role" => "IMPLEMENTER",
      "selection_rule" => "FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST",
      "semantic_digest" => "sha256:" <> String.duplicate("b", 64)
    }
  end

  defp read_json(path) do
    {:ok, body} = File.read(path)
    {:ok, doc} = JSON.decode(body)
    doc
  end

  defp short_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end
end
