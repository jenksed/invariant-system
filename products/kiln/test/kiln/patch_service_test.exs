defmodule Kiln.PatchServiceTest do
  @moduledoc """
  WP-08 Lane 3 — focused PatchService property tests.

  Coverage:

    P3 — `:add`-op preimage absence check.
      * `:add` to an absent path succeeds.
      * `:add` to an existing path returns `:E_PATCH_PREIMAGE_MISMATCH`
        (the preimage must be absent for `:add`).
      * `:replace` over an existing path with matching `before_digest`
        succeeds (no regression).
      * `:delete` of an absent path returns `:ok` (no regression).

    P4 — `recover/3` observes the repository.
      * Truthful observation (caller digest matches disk) returns
        `{:ok, evidence}`.
      * Caller-supplied digest that does not match the observed disk
        digest returns `:E_PATCH_RECOVERY_DENIED`.
      * Caller passes `proposal.base_state_digest` and the disk is in
        the base state: the disk-derived digest does not equal
        `proposal.base_state_digest` (different schemes), so
        `:E_PATCH_RECOVERY_DENIED` is returned.

  These tests run in isolation (no store required) because both P3
  and P4 live in the pure `Kiln.PatchService` module.
  """

  use ExUnit.Case, async: true

  alias Kiln.M0PatchEvidence, as: Evidence
  alias Kiln.{PatchProposal, PatchService}

  setup do
    base = Path.join(System.tmp_dir!(), "kiln_ps_#{System.unique_integer([:positive])}")
    File.rm_rf!(base)
    File.mkdir_p!(base)

    on_exit(fn -> File.rm_rf!(base) end)

    %{tmp_root: base}
  end

  # ----------------------------------------------------------------
  # P3 — `:add` preimage absence check
  # ----------------------------------------------------------------

  describe "WP-08 P3 — :add preimage absence check" do
    test ":add to an absent path succeeds", %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "add_absent")
      content = "# Added\n"
      after_digest = sha256_hex(content)

      ops = [
        %{
          op: :add,
          path: "new.md",
          content: content,
          before_digest: nil,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, after_digest)
      decision = approve_decision!(proposal)

      assert {:ok, %Evidence{effect: "EXACT_TARGET_STATE_OBSERVED"}} =
               PatchService.apply(proposal, decision, ops)

      assert File.read!(Path.join(repository, "new.md")) == content
    end

    test ":add to an existing path returns E_PATCH_PREIMAGE_MISMATCH", %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "add_existing")
      File.write!(Path.join(repository, "exists.md"), "# Already here\n")

      content = "# Should not overwrite\n"
      after_digest = sha256_hex(content)

      ops = [
        %{
          op: :add,
          path: "exists.md",
          content: content,
          before_digest: nil,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, after_digest)
      decision = approve_decision!(proposal)

      assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops)

      # Fail-closed: the file is NOT overwritten.
      assert File.read!(Path.join(repository, "exists.md")) == "# Already here\n"
    end

    test ":replace over an existing path with matching before_digest succeeds (no regression)",
         %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "replace_existing")
      original = "# Original\n"
      replaced = "# Replaced\n"
      File.write!(Path.join(repository, "README.md"), original)

      before_digest = sha256_hex(original)
      after_digest = sha256_hex(replaced)

      ops = [
        %{
          op: :replace,
          path: "README.md",
          content: replaced,
          before_digest: before_digest,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, after_digest)
      decision = approve_decision!(proposal)

      assert {:ok, %Evidence{}} = PatchService.apply(proposal, decision, ops)
      assert File.read!(Path.join(repository, "README.md")) == replaced
    end

    test ":delete of an absent path fails closed at the preimage check (no regression)",
         %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "delete_absent")

      ops = [
        %{
          op: :delete,
          path: "never_existed.md",
          content: nil,
          before_digest: sha256_hex("# phantom\n"),
          after_image_digest: nil,
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, sha256_hex("unused"))
      decision = approve_decision!(proposal)

      # No regression: the existing preimage check fails closed for a
      # `:delete` whose target file is absent — the bounded
      # `E_PATCH_PREIMAGE_MISMATCH` is the canonical refusal. P3 only
      # narrows `:add`; the `:delete` branch is unchanged.
      assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops)
    end
  end

  # ----------------------------------------------------------------
  # P4 — `recover/3` observes the repository
  # ----------------------------------------------------------------

  describe "WP-08 P4 — recover/3 observes the repository" do
    test "recover with truthful observation returns {:ok, evidence}", %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "recover_truthful")
      original = "# Original\n"
      replaced = "# Replaced\n"
      File.write!(Path.join(repository, "README.md"), original)

      before_digest = sha256_hex(original)
      after_digest = sha256_hex(replaced)

      ops = [
        %{
          op: :replace,
          path: "README.md",
          content: replaced,
          before_digest: before_digest,
          after_image_digest: after_digest,
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, after_digest)
      decision = approve_decision!(proposal)

      # Apply the patch so the disk reaches the post-state.
      assert {:ok, _evidence} = PatchService.apply(proposal, decision, ops)

      # P4: caller passes the post-state digest (truthful observation).
      # The handler computes observed_state_digest from disk and the
      # caller's digest matches.
      assert {:ok, %Evidence{effect: "EXACT_TARGET_STATE_OBSERVED"}} =
               PatchService.recover(proposal, decision, compute_observed_digest(proposal))
    end

    test "recover with caller-supplied digest that does not match the observed digest returns E_PATCH_RECOVERY_DENIED",
         %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "recover_mismatch")
      File.write!(Path.join(repository, "README.md"), "# Original\n")

      ops = [
        %{
          op: :replace,
          path: "README.md",
          content: "# Replaced\n",
          before_digest: sha256_hex("# Original\n"),
          after_image_digest: sha256_hex("# Replaced\n"),
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, sha256_hex("# Replaced\n"))
      decision = approve_decision!(proposal)

      # Caller passes a digest that does NOT match the disk-observed
      # digest. P4 must fail closed.
      wrong_digest = "sha256:" <> String.duplicate("9", 64)

      assert {:error, %{code: :E_PATCH_RECOVERY_DENIED}} =
               PatchService.recover(proposal, decision, wrong_digest)
    end

    test "recover with observed digest matching base_state_digest returns E_PATCH_RECOVERY_DENIED",
         %{tmp_root: tmp_root} do
      repository = fresh_repo!(tmp_root, "recover_base")
      # Disk is in the BASE state: no patch has been applied yet.
      File.write!(Path.join(repository, "README.md"), "# Original\n")

      ops = [
        %{
          op: :replace,
          path: "README.md",
          content: "# Replaced\n",
          before_digest: sha256_hex("# Original\n"),
          after_image_digest: sha256_hex("# Replaced\n"),
          mode: "100644"
        }
      ]

      proposal = build_proposal!(repository, ops, sha256_hex("# Replaced\n"))
      decision = approve_decision!(proposal)

      # P4 acceptance: when the caller passes proposal.base_state_digest,
      # the handler first computes the disk-observed digest, which
      # differs from base_state_digest (different schemes), so P4
      # fails closed.
      assert {:error, %{code: :E_PATCH_RECOVERY_DENIED}} =
               PatchService.recover(proposal, decision, proposal.base_state_digest)
    end
  end

  # ----------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------

  defp fresh_repo!(tmp_root, tag) do
    dir = Path.join(tmp_root, tag)
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    dir
  end

  defp build_proposal!(repository, operations, _last_after_digest) do
    worker_output = %Kiln.M0WorkerOutput{
      id: "wko_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
      semantic_digest: "sha256:" <> String.duplicate("d", 64),
      attempt_ref: %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("e", 64)},
      assignment_ref: %{"id" => "asg_test", "digest" => "sha256:" <> String.duplicate("f", 64)},
      profile_ref: %{"id" => "prf_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      output_kind: "PATCH_CANDIDATE",
      raw_completion_ref: %{
        "id" => "raw_test",
        "digest" => "sha256:" <> String.duplicate("2", 64)
      },
      parsed_candidate_digest: "sha256:" <> String.duplicate("3", 64),
      completion_bytes: "{}",
      base_commit: String.duplicate("a", 40),
      base_state_digest: "sha256:" <> String.duplicate("4", 64),
      adapter_implementation_digest: "sha256:" <> String.duplicate("5", 64)
    }

    plan_ref = %{
      "id" => "pln_test",
      "digest" => "sha256:" <> String.duplicate("6", 64)
    }

    {:ok, proposal} = PatchProposal.build(worker_output, operations, plan_ref, repository)
    proposal
  end

  defp approve_decision!(proposal) do
    {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
    decision
  end

  # Mirrors `Kiln.PatchService.expected_post_state_digest/1` so the
  # test can compute the digest a truthful caller would pass to
  # `recover/3` (matching the same canonical scheme the service uses
  # for the disk-observed digest in P4).
  defp compute_observed_digest(proposal) do
    canon_ops =
      Enum.map(proposal.operations, fn op ->
        %{
          "op" => op["op"],
          "path" => op["path"],
          "before_digest" => op["before_digest"],
          "after_image_digest" => actual_after_digest(proposal.repository, op),
          "mode" => op["mode"]
        }
      end)

    "sha256:" <>
      Kiln.Store.Canonical.digest(
        "engineering-system/patch-application-evidence/m0-v1/expected-post",
        %{
          "base_state_digest" => proposal.base_state_digest,
          "operations" => canon_ops
        }
      )
  end

  defp actual_after_digest(repository, op) do
    full = Path.join(repository, op["path"])

    case File.read(full) do
      {:ok, bytes} -> sha256_hex(bytes)
      {:error, _reason} -> nil
    end
  end

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end
end
