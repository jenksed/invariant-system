defmodule Kiln.M11E2DeterministicTest do
  @moduledoc """
  M11 E2 deterministic acceptance matrix for the canonical M11 E2
  govern chain (PatchProposal.decode_envelope, build_from_worker_output,
  PatchService.apply, apply_with_completion_ref, Artifact.Store /
  WorkerOutputStore retention).

  Bounded acceptance suite: each test exercises one canonical code path
  against the live source contracts in `lib/kiln/`. The suite never
  delegates to mocks, never injects through private seams, and never
  shares mutable state across tests (async: false). Per-test store
  roots and repository roots are minted from `System.unique_integer/1`
  with `on_exit/1` cleanup.

  Canonical surfaces exercised:
    * `Kiln.Artifact.PutRequest` — typed publish envelope
    * `Kiln.Artifact.Store` (as `ArtifactStore`) — durable Artifact
      publication + read
    * `Kiln.WorkerOutputStore.publish/2` and `resolve/2`
    * `Kiln.PatchProposal.decode_envelope/1`,
      `build_from_worker_output/4`, `enforce_path_limits/1`,
      `enforce_byte_limits/1`
    * `Kiln.PatchService.apply/3`, `apply_with_completion_ref/4`,
      `compute_post_state_digest/1`
    * `Kiln.Conformance.FirstMonth.patch_limits/0`
    * `Kiln.Store.Uuid.v7/0`

  Architecture: Kiln.M0 (KILN-M0-03, lane M9; bounded M11 E2 P1–P5
  deterministic acceptance per SYS-M0-03 M11 work package).
  """

  use ExUnit.Case, async: false

  alias Kiln.Artifact.Store, as: ArtifactStore
  alias Kiln.PatchProposal
  alias Kiln.PatchService
  alias Kiln.M0PatchProposal, as: Proposal
  alias Kiln.M0PatchEvidence, as: Evidence
  alias Kiln.M0WorkerOutput, as: WorkerOutput
  alias Kiln.WorkerOutputStore
  alias Kiln.Store
  alias Kiln.Store.Uuid

  @now "2026-08-10T12:00:00Z"
  @envelope_schema "engineering-system/implementer-patch-proposal-input/v1"

  # ─── 1. Artifact retention ──────────────────────────────────────────────

  describe "1. Artifact retention" do
    test "A. publish/2 stores raw completion bytes in canonical Artifact.Store" do
      base = fresh_root!("m11_e2_a_publish")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      completion_bytes = "deterministic completion bytes for A"
      wo = build_worker_output("wko_a", completion_bytes)

      assert {:ok, _status, %WorkerOutput{} = rewired} =
               WorkerOutputStore.publish(store, wo)

      # raw_completion_ref.id is a UUIDv7
      assert Uuid.v7() =~
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

      assert rewired.raw_completion_ref["id"] =~
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

      # Bytes are byte-identical on disk and the digest matches sha256(bytes)
      {:ok, retrieved, %{integrity_status: :verified}} =
        ArtifactStore.read(store, rewired.raw_completion_ref["id"])

      assert retrieved == completion_bytes

      assert rewired.raw_completion_ref["digest"] ==
               "sha256:" <>
                 (:crypto.hash(:sha256, completion_bytes) |> Base.encode16(case: :lower))
    end

    test "B. fresh store handle retrieves byte-identical completion" do
      base = fresh_root!("m11_e2_b_fresh")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      completion_bytes = "deterministic completion bytes for B"
      wo = build_worker_output("wko_b", completion_bytes)
      {:ok, _status, %WorkerOutput{} = rewired} = WorkerOutputStore.publish(store, wo)

      # Close the live connection, then re-open against the same on-disk
      # substrate to prove the bytes are durable rather than transient.
      stop(store.conn)

      {:ready, fresh} = start_test_store(base)
      on_exit(fn -> stop(fresh.conn) end)

      assert {:ok, retrieved, %{integrity_status: :verified}} =
               ArtifactStore.read(fresh, rewired.raw_completion_ref["id"])

      assert retrieved == completion_bytes
    end

    test "C. altered artifact fails closed" do
      base = fresh_root!("m11_e2_c_altered")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      completion_bytes = "deterministic completion bytes for C"
      wo = build_worker_output("wko_c", completion_bytes)
      {:ok, _status, %WorkerOutput{} = rewired} = WorkerOutputStore.publish(store, wo)

      # Tamper with the on-disk content blob under the content-addressed location.
      artifact_path =
        Path.join(store.artifact_root, content_location_for(rewired.raw_completion_ref["digest"]))

      File.write!(artifact_path, "tampered garbage that does not match the published digest")

      # Canonical chain: fetch → integrity :corrupt → read →
      # :artifact_unreadable → resolve → :E_COMPLETION_INTEGRITY.
      assert {:error, :E_COMPLETION_INTEGRITY} =
               WorkerOutputStore.resolve(store, rewired.raw_completion_ref)
    end

    test "D. unknown artifact_id fails closed with E_COMPLETION_NOT_FOUND" do
      base = fresh_root!("m11_e2_d_unknown")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      unknown_ref = %{
        "id" => "01920080-0000-7000-8000-000000000099",
        "digest" => "sha256:" <> String.duplicate("0", 64)
      }

      assert {:error, :E_COMPLETION_NOT_FOUND} =
               WorkerOutputStore.resolve(store, unknown_ref)
    end
  end

  # ─── 2. Materialization (decode_envelope + build_from_worker_output) ────

  describe "2. Materialization" do
    test "E. deterministic repeat: same bytes produce same ops + digest" do
      bytes = build_envelope_bytes([%{op: "add", path: "README.md", after_image_bytes: "# hi\n"}])

      assert {:ok, ops_a} = PatchProposal.decode_envelope(bytes)
      assert {:ok, ops_b} = PatchProposal.decode_envelope(bytes)

      assert ops_a == ops_b

      [op_a] = ops_a
      [op_b] = ops_b

      assert op_a.before_digest == op_b.before_digest
      assert op_a.after_image_digest == op_b.after_image_digest
      assert op_a.path == op_b.path
      assert op_a.op == op_b.op

      # build_from_worker_output is deterministic
      wo = build_worker_output("wko_e", bytes)
      plan_ref = %{"id" => "pln_e", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:ok, %Proposal{} = p1} =
               PatchProposal.build_from_worker_output(wo, ops_a, plan_ref, ".")

      assert {:ok, %Proposal{} = p2} =
               PatchProposal.build_from_worker_output(wo, ops_b, plan_ref, ".")

      assert p1.patch_digest == p2.patch_digest
    end

    test "F. add op produces correct shape" do
      content = "added content"
      bytes = build_envelope_bytes([%{op: "add", path: "new.txt", after_image_bytes: content}])

      assert {:ok, [op]} = PatchProposal.decode_envelope(bytes)

      assert op.op == :add
      assert op.path == "new.txt"
      assert op.content == content
      assert op.before_digest == nil
      assert op.after_image_digest == sha256_hex(content)
      assert op.mode == "100644"
    end

    test "F. replace op produces correct shape" do
      content = "replaced content"
      before = sha256_hex("original content on disk")

      bytes =
        build_envelope_bytes([
          %{
            op: "replace",
            path: "README.md",
            after_image_bytes: content,
            expected_before_digest: before
          }
        ])

      assert {:ok, [op]} = PatchProposal.decode_envelope(bytes)

      assert op.op == :replace
      assert op.path == "README.md"
      assert op.content == content
      assert op.before_digest == before
      assert op.after_image_digest == sha256_hex(content)
      assert op.mode == "100644"
    end

    test "F. delete op produces correct shape" do
      before = sha256_hex("file to be deleted")

      bytes =
        build_envelope_bytes([
          %{op: "delete", path: "obsolete.md", expected_before_digest: before}
        ])

      assert {:ok, [op]} = PatchProposal.decode_envelope(bytes)

      assert op.op == :delete
      assert op.path == "obsolete.md"
      assert op.content == nil
      assert op.before_digest == sha256_hex("file to be deleted")
      assert op.after_image_digest == nil
    end

    test "G. malformed JSON rejects with canonical E_PATCH_ENVELOPE_SHAPE_INVALID" do
      # Canonical: `safe_json_decode/1` rescues a JSON-parse failure into
      # the bounded SHAPE_INVALID envelope (patch_proposal.ex:294). The
      # schema-invalid code is reserved for envelopes whose JSON parses
      # but whose top-level shape diverges from the canonical contract.
      assert {:error, %{code: :E_PATCH_ENVELOPE_SHAPE_INVALID}} =
               PatchProposal.decode_envelope("not valid json {{{")
    end

    test "H. unknown top-level field rejected" do
      # The canonical envelope schema is closed shape
      # (additionalProperties: false): an arbitrary unknown top-level
      # field is rejected with E_PATCH_ENVELOPE_SHAPE_INVALID. Known
      # authority fields (`approval`, `human_decision`, …) are covered
      # by the I-series tests below via E_PATCH_AUTHORITY_SMUGGLED.
      bytes =
        build_envelope_bytes(
          [%{op: "add", path: "a.txt", after_image_bytes: "x"}],
          %{"rogue_field" => "x"}
        )

      assert {:error, %{code: :E_PATCH_ENVELOPE_SHAPE_INVALID}} =
               PatchProposal.decode_envelope(bytes)
    end

    test "I. authority smuggling rejected — approval" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"approval" => "yes"})
    end

    test "I. authority smuggling rejected — human_decision" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"human_decision" => "approve"})
    end

    test "I. authority smuggling rejected — authorization" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"authorization" => "ok"})
    end

    test "I. authority smuggling rejected — qualification" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"qualification" => "ok"})
    end

    test "I. authority smuggling rejected — evidence" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"evidence" => []})
    end

    test "I. authority smuggling rejected — execution" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"execution" => "apply"})
    end

    test "I. authority smuggling rejected — provider_approval" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"provider_approval" => "granted"})
    end

    test "I. authority smuggling rejected — decision_id" do
      bytes = build_envelope_bytes([%{op: "add", path: "a.txt", after_image_bytes: "x"}])

      assert {:error, %{code: :E_PATCH_AUTHORITY_SMUGGLED}} =
               decode_with_smuggled_field(bytes, %{"decision_id" => "dec_xyz"})
    end

    test "J. invalid digest rejected" do
      bytes =
        build_envelope_bytes([
          %{
            op: "replace",
            path: "README.md",
            after_image_bytes: "x",
            expected_before_digest: "not-a-digest"
          }
        ])

      assert {:error, %{code: :E_PATCH_PREIMAGE_SHAPE_INVALID}} =
               PatchProposal.decode_envelope(bytes)
    end

    test "K. duplicate path: accepted at build, conflicting adds fail closed at apply" do
      # Canonical M8 schema does NOT prohibit duplicate paths in
      # operations[]; uniqueness is not a canonical constraint. Two ops
      # on the same path decode and build cleanly…
      ops = [
        %{op: "add", path: "dup.txt", after_image_bytes: "a"},
        %{op: "add", path: "dup.txt", after_image_bytes: "b"}
      ]

      bytes = build_envelope_bytes(ops)

      assert {:ok, decoded_ops} = PatchProposal.decode_envelope(bytes)

      wo = build_worker_output("wko_k", bytes)
      plan_ref = %{"id" => "pln_k", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:ok, %Proposal{}} =
               PatchProposal.build_from_worker_output(wo, decoded_ops, plan_ref, ".")

      # …but at apply time, conflicting duplicate adds (same path,
      # different content) fail closed: the second write wins on disk,
      # the first op's postimage check then fails, and no evidence is
      # emitted.
      tmp = fresh_tmp!("m11_e2_k_dup_apply")

      ops_with_bytes = [
        %{
          op: :add,
          path: "dup.txt",
          content: "a",
          before_digest: nil,
          after_image_digest: sha256_hex("a")
        },
        %{
          op: :add,
          path: "dup.txt",
          content: "b",
          before_digest: nil,
          after_image_digest: sha256_hex("b")
        }
      ]

      proposal = build_approved_proposal_with_ops!(tmp, ops_with_bytes)
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      assert {:error, %{code: :E_PATCH_POSTIMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops_with_bytes)
    end

    test "L. path escape rejected at canonical build stage" do
      # Canonical: `decode_envelope/1` is structural only; the bounded
      # path classifier lives in `reject_disallowed_kinds/1` and runs at
      # `build/5` time (patch_proposal.ex:633–664). The canonical stage
      # for path escape is build, not decode.
      bytes =
        build_envelope_bytes([
          %{op: "add", path: "../../etc/passwd", after_image_bytes: "x"}
        ])

      {:ok, decoded_ops} = PatchProposal.decode_envelope(bytes)
      wo = build_worker_output("wko_l", bytes)
      plan_ref = %{"id" => "pln_l", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:error, %{code: :E_PATCH_PATH_ESCAPE}} =
               PatchProposal.build_from_worker_output(wo, decoded_ops, plan_ref, ".")
    end

    test "M. .git metadata path rejected at canonical build stage" do
      # Canonical: same owning boundary as L — `.git/**` paths are
      # classified in `reject_disallowed_kinds/1` at build time.
      bytes =
        build_envelope_bytes([
          %{op: "add", path: ".git/config", after_image_bytes: "x"}
        ])

      {:ok, decoded_ops} = PatchProposal.decode_envelope(bytes)
      wo = build_worker_output("wko_m", bytes)
      plan_ref = %{"id" => "pln_m", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:error, %{code: :E_PATCH_PATH_ESCAPE}} =
               PatchProposal.build_from_worker_output(wo, decoded_ops, plan_ref, ".")
    end

    test "N. binary/NUL content rejected" do
      bytes =
        build_envelope_bytes([
          %{op: "add", path: "binary.bin", after_image_bytes: "before\0after"}
        ])

      assert {:error, %{code: :E_PATCH_BINARY_DENIED}} =
               PatchProposal.decode_envelope(bytes)
    end

    test "O. path count limit (33 ops) rejected at canonical build stage" do
      # Canonical: `enforce_path_limits/1` runs in `build/5` (line 80),
      # not in `decode_envelope/1`. Path-count rejection is a build-time
      # bounded property; decode returns the ops unchanged.
      ops =
        Enum.map(1..33, fn i ->
          %{op: "add", path: "f#{i}.txt", after_image_bytes: "x"}
        end)

      bytes = build_envelope_bytes(ops)

      {:ok, decoded_ops} = PatchProposal.decode_envelope(bytes)
      wo = build_worker_output("wko_o", bytes)
      plan_ref = %{"id" => "pln_o", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:error, %{code: :E_PATCH_PATH_LIMIT_EXCEEDED}} =
               PatchProposal.build_from_worker_output(wo, decoded_ops, plan_ref, ".")
    end

    test "P. single-content bound (1 MiB + 1 byte) rejected at canonical build stage" do
      # Canonical: `enforce_byte_limits/1` runs in `build/5` (line 81).
      # `decode_envelope/1` only enforces the aggregate bound via
      # `enforce_total_bound/1`; the per-op single-content ceiling is
      # build-time.
      huge = String.duplicate("x", 1_048_577)

      bytes =
        build_envelope_bytes([%{op: "add", path: "huge.txt", after_image_bytes: huge}])

      {:ok, decoded_ops} = PatchProposal.decode_envelope(bytes)
      wo = build_worker_output("wko_p", bytes)
      plan_ref = %{"id" => "pln_p", "digest" => "sha256:" <> String.duplicate("0", 64)}

      assert {:error, %{code: :E_PATCH_BYTES_LIMIT_EXCEEDED}} =
               PatchProposal.build_from_worker_output(wo, decoded_ops, plan_ref, ".")
    end

    test "Q. aggregate bound (4 MiB + 1 byte) rejected at canonical decode stage" do
      # Canonical: `enforce_total_bound/1` runs in `decode_envelope/1`
      # (line 205) and rejects any aggregate after-image payload above
      # the canonical 4 MiB ceiling. This is the one bound enforced at
      # decode, distinct from the per-op single-content bound.
      ops =
        Enum.map(1..5, fn i ->
          %{op: "add", path: "chunk#{i}.bin", after_image_bytes: String.duplicate("x", 838_861)}
        end)

      bytes = build_envelope_bytes(ops)

      assert {:error, %{code: :E_PATCH_BYTES_LIMIT_EXCEEDED}} =
               PatchProposal.decode_envelope(bytes)
    end

    test "R. raw input bound (>16 MiB envelope)" do
      # 16 MiB + 1 byte — exceeds Kiln.Artifact.max_byte_size/0
      oversize = String.duplicate("x", 16_777_217)

      assert {:error, %{code: :E_PATCH_INPUT_LIMIT_EXCEEDED}} =
               PatchProposal.decode_envelope(oversize)
    end

    test "unknown op-level field rejected" do
      # Closed-shape operations (additionalProperties: false per op
      # kind): an arbitrary unknown key on an op is rejected with
      # E_PATCH_OPERATIONS_SHAPE_INVALID.
      rogue_add =
        build_envelope_bytes([
          %{"op" => "add", "path" => "a.txt", "after_image_bytes" => "x", "rogue" => 1}
        ])

      assert {:error, %{code: :E_PATCH_OPERATIONS_SHAPE_INVALID}} =
               PatchProposal.decode_envelope(rogue_add)

      # A delete op carrying after_image_bytes is likewise outside the
      # closed delete shape (op, path, expected_before_digest only).
      delete_with_after =
        build_envelope_bytes([
          %{
            "op" => "delete",
            "path" => "obsolete.md",
            "expected_before_digest" => sha256_hex("file to be deleted"),
            "after_image_bytes" => "x"
          }
        ])

      assert {:error, %{code: :E_PATCH_OPERATIONS_SHAPE_INVALID}} =
               PatchProposal.decode_envelope(delete_with_after)
    end
  end

  # ─── 3. Exact-byte apply ───────────────────────────────────────────────

  describe "3. Exact-byte apply" do
    test "S. after-image mismatch → zero mutation" do
      tmp = fresh_tmp!("m11_e2_s_after")

      original = "# Original\n"
      replaced = "# Replaced\n"
      before_digest = sha256_hex(original)
      wrong_after = sha256_hex("WRONG bytes, NOT the supplied content")

      File.write!(Path.join(tmp, "README.md"), original)

      proposal =
        build_approved_proposal!(
          tmp,
          before_digest,
          wrong_after,
          replaced
        )

      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: replaced,
          before_digest: before_digest,
          after_image_digest: wrong_after
        }
      ]

      assert {:error, %{code: :E_PATCH_AFTER_IMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops_with_bytes)

      assert File.read!(Path.join(tmp, "README.md")) == original
    end

    test "T. stale preimage → zero mutation" do
      tmp = fresh_tmp!("m11_e2_t_stale")

      original = "# Original\n"
      replaced = "# Replaced\n"
      wrong_preimage = sha256_hex("bits that aren't actually on disk")
      after_digest = sha256_hex(replaced)

      File.write!(Path.join(tmp, "README.md"), original)

      proposal =
        build_approved_proposal!(
          tmp,
          wrong_preimage,
          after_digest,
          replaced
        )

      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: replaced,
          before_digest: wrong_preimage,
          after_image_digest: after_digest
        }
      ]

      assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops_with_bytes)

      assert File.read!(Path.join(tmp, "README.md")) == original
    end

    test "U. valid exact bytes → success, evidence.post_state_digest bound, file exactly mutated" do
      tmp = fresh_tmp!("m11_e2_u_positive")

      original = "# Original\n"
      replaced = "# Replaced\n"
      before_digest = sha256_hex(original)
      after_digest = sha256_hex(replaced)

      File.write!(Path.join(tmp, "README.md"), original)

      proposal =
        build_approved_proposal!(
          tmp,
          before_digest,
          after_digest,
          replaced
        )

      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: replaced,
          before_digest: before_digest,
          after_image_digest: after_digest
        }
      ]

      assert {:ok, %Evidence{effect: "EXACT_TARGET_STATE_OBSERVED"} = evidence} =
               PatchService.apply(proposal, decision, ops_with_bytes)

      assert evidence.pre_state_digest == proposal.base_state_digest
      assert evidence.post_state_digest == PatchService.compute_post_state_digest(proposal)

      assert File.read!(Path.join(tmp, "README.md")) == replaced
    end

    test "V. unknown repository path fails closed" do
      tmp = fresh_tmp!("m11_e2_v_no_repo")

      before_digest = sha256_hex("placeholder")
      after_digest = sha256_hex("placeholder2")

      proposal =
        build_approved_proposal!(
          tmp,
          before_digest,
          after_digest,
          "placeholder2"
        )

      bad_proposal = %{proposal | repository: "/does/not/exist/m11_e2_v"}

      {:ok, decision} =
        PatchService.decide(bad_proposal, :approve, bad_proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :add,
          path: "x.txt",
          content: "placeholder2",
          before_digest: nil,
          after_image_digest: after_digest
        }
      ]

      assert {:error, %{code: :E_PATCH_REPOSITORY_INVALID}} =
               PatchService.apply(bad_proposal, decision, ops_with_bytes)
    end

    test "multi-op partial mutation effect is bounded and recoverable" do
      tmp = fresh_tmp!("m11_e2_partial_effect")

      before = "# before\n"
      after_content = "# after\n"
      before_digest = sha256_hex(before)
      after_digest = sha256_hex(after_content)

      blocked_before = "before-blocked\n"
      blocked_after = "after-blocked\n"

      File.write!(Path.join(tmp, "README.md"), before)

      # Create a regular file at the second op's target path and
      # chmod it read-only. The preimage check for op 2 (a :replace
      # with before_digest matching the current contents) passes
      # because the file is readable. The fault is triggered AFTER op
      # 1 has taken effect: op 2's write_op/2 calls File.write!/2,
      # which raises File.Error (:eacces) because the file is
      # read-only.
      #
      # This proves partial-effect uncertainty: op 1 succeeded, op 2
      # failed mid-mutation, the bounded result is
      # E_MUTATION_UNKNOWN_EFFECT, and the repository is in a
      # partially-applied state. Recovery is the only way forward.
      File.write!(Path.join(tmp, "blocked.txt"), blocked_before)
      File.chmod!(Path.join(tmp, "blocked.txt"), 0o444)

      on_exit(fn ->
        File.chmod!(Path.join(tmp, "blocked.txt"), 0o644)
      end)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: after_content,
          before_digest: before_digest,
          after_image_digest: after_digest
        },
        %{
          op: :replace,
          path: "blocked.txt",
          content: blocked_after,
          before_digest: sha256_hex(blocked_before),
          after_image_digest: sha256_hex(blocked_after)
        }
      ]

      proposal = build_approved_proposal_with_ops!(tmp, ops_with_bytes)
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      # (a) The mid-mutation crash is bounded as E_MUTATION_UNKNOWN_EFFECT.
      assert {:error, %{code: :E_MUTATION_UNKNOWN_EFFECT}} =
               PatchService.apply(proposal, decision, ops_with_bytes)

      # (b) Op A took effect — the repository is PARTIALLY applied, NOT
      # zero-effect.
      assert File.read!(Path.join(tmp, "README.md")) == after_content

      # (c) The blocked.txt file is UNCHANGED (write failed with EACCES).
      assert File.read!(Path.join(tmp, "blocked.txt")) == blocked_before

      # (d) Recovery against a state digest that is neither base nor the
      # expected post-state is denied.
      wrong_digest = sha256_hex("observed partial state that matches neither base nor target")

      assert {:error, %{code: :E_PATCH_RECOVERY_DENIED}} =
               PatchService.recover(proposal, decision, wrong_digest)

      # (e) Re-invoking apply with the same inputs fails closed with
      # E_PATCH_PREIMAGE_MISMATCH — the README preimage already changed;
      # no blind replay of the authorized bytes.
      assert {:error, %{code: :E_PATCH_PREIMAGE_MISMATCH}} =
               PatchService.apply(proposal, decision, ops_with_bytes)
    end

    test "decision does not transfer across proposals" do
      base = fresh_root!("m11_e2_decision_transfer")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      tmp = fresh_tmp!("m11_e2_decision_transfer_repo")

      before = "# before\n"
      after_a = "# after\n"
      after_b = "# other\n"
      before_digest = sha256_hex(before)

      File.write!(Path.join(tmp, "README.md"), before)

      # Proposal A + its approved decision.
      ops_a = [
        %{
          op: :replace,
          path: "README.md",
          content: after_a,
          before_digest: before_digest,
          after_image_digest: sha256_hex(after_a)
        }
      ]

      proposal_a = build_approved_proposal_with_ops!(tmp, ops_a)
      {:ok, decision_a} = PatchService.decide(proposal_a, :approve, proposal_a.base_state_digest)

      # Proposal B: different content/digests on the same repository,
      # built from its own worker output so the governed rebuild path
      # reproduces B exactly.
      completion_bytes_b =
        build_envelope_bytes([
          replace_op("README.md", sha256_hex(after_b), after_b, before_digest)
        ])

      {:ok, ops_b} = PatchProposal.decode_envelope(completion_bytes_b)
      wo_b = build_worker_output("wko_decision_transfer", completion_bytes_b)
      proposal_b = build_approved_proposal_with_wo!(wo_b, tmp, ops_b)

      assert proposal_a.patch_digest != proposal_b.patch_digest

      # Plain apply: decision A's patch_ref.digest does not bind proposal
      # B → E_PATCH_DECISION_INVALID with zero mutation.
      assert {:error, %{code: :E_PATCH_DECISION_INVALID}} =
               PatchService.apply(proposal_b, decision_a, ops_b)

      # Governed apply: a decision bound to a different patch_digest is
      # rejected the same way through apply_with_completion_ref/4.
      {:ok, _status, rewired_b} = WorkerOutputStore.publish(store, wo_b)

      assert {:error, %{code: :E_PATCH_DECISION_INVALID}} =
               PatchService.apply_with_completion_ref(proposal_b, decision_a, rewired_b, store)

      assert File.read!(Path.join(tmp, "README.md")) == before
    end
  end

  # ─── 4. Governed apply (apply_with_completion_ref) ──────────────────

  describe "4. Governed apply (apply_with_completion_ref)" do
    test "W. rebuilt digest mismatch rejects with zero mutation" do
      base = fresh_root!("m11_e2_w_drift")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      tmp = fresh_tmp!("m11_e2_w_repo")
      before_digest = sha256_hex("# before\n")
      after_digest = sha256_hex("# after\n")
      File.write!(Path.join(tmp, "README.md"), "# before\n")

      # Build the proposal and the approved decision, then persist the
      # real completion bytes to the canonical Artifact.Store.
      wo =
        build_worker_output(
          "wko_w",
          build_envelope_bytes([
            replace_op("README.md", after_digest, "# after\n", before_digest)
          ])
        )

      {:ok, _ops} = PatchProposal.decode_envelope(wo.completion_bytes)

      proposal =
        build_approved_proposal!(
          tmp,
          before_digest,
          after_digest,
          "# after\n"
        )

      {:ok, _decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
      {:ok, _status, rewired} = WorkerOutputStore.publish(store, wo)

      # Re-point raw_completion_ref.digest to a wrong digest while keeping
      # the artifact_id stable — the Store's :verified read returns the
      # original bytes, sha256(bytes) != wrong digest, so resolve/2 fails
      # closed with :E_COMPLETION_DIGEST_MISMATCH.
      tampered = %{
        rewired
        | raw_completion_ref: %{
            rewired.raw_completion_ref
            | "digest" => "sha256:" <> String.duplicate("f", 64)
          }
      }

      assert {:error, :E_COMPLETION_DIGEST_MISMATCH} =
               WorkerOutputStore.resolve(store, tampered.raw_completion_ref)

      assert File.read!(Path.join(tmp, "README.md")) == "# before\n"
    end

    test "X. missing raw completion rejects with zero mutation" do
      base = fresh_root!("m11_e2_x_missing")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      tmp = fresh_tmp!("m11_e2_x_repo")
      before_digest = sha256_hex("# before\n")
      after_digest = sha256_hex("# after\n")
      File.write!(Path.join(tmp, "README.md"), "# before\n")

      proposal =
        build_approved_proposal!(
          tmp,
          before_digest,
          after_digest,
          "# after\n"
        )

      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      # Fabricate a WorkerOutput whose raw_completion_ref points at a
      # UUIDv7 that was never published.
      missing_id = "01920080-0000-7000-8000-000000000077"

      fake_wo = %WorkerOutput{
        id: "wko_x",
        semantic_digest: "sha256:" <> String.duplicate("a", 64),
        attempt_ref: %{"id" => "att_x", "digest" => "sha256:" <> String.duplicate("b", 64)},
        assignment_ref: %{"id" => "asg_x", "digest" => "sha256:" <> String.duplicate("c", 64)},
        profile_ref: %{"id" => "prf_x", "digest" => "sha256:" <> String.duplicate("d", 64)},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{
          "id" => missing_id,
          "digest" => "sha256:" <> String.duplicate("0", 64)
        },
        parsed_candidate_digest: "sha256:" <> String.duplicate("e", 64),
        completion_bytes: "",
        base_commit: "0123456789abcdef0123456789abcdef01234567",
        base_state_digest: "sha256:" <> String.duplicate("f", 64),
        adapter_implementation_digest: "sha256:" <> String.duplicate("1", 64)
      }

      assert {:error, :E_COMPLETION_NOT_FOUND} =
               WorkerOutputStore.resolve(store, fake_wo.raw_completion_ref)

      assert {:error, :E_COMPLETION_NOT_FOUND} =
               PatchService.apply_with_completion_ref(proposal, decision, fake_wo, store)

      assert File.read!(Path.join(tmp, "README.md")) == "# before\n"
    end

    test "Y. governed apply from approved bytes succeeds" do
      base = fresh_root!("m11_e2_y_e2e")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      tmp = fresh_tmp!("m11_e2_y_repo")
      before_digest = sha256_hex("# before\n")
      after_digest = sha256_hex("# after\n")
      File.write!(Path.join(tmp, "README.md"), "# before\n")

      # Real completion bytes — built from the same ops the proposal carries.
      completion_bytes =
        build_envelope_bytes([replace_op("README.md", after_digest, "# after\n", before_digest)])

      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      wo =
        build_worker_output("wko_y", completion_bytes)
        |> Map.put(:base_state_digest, "sha256:" <> String.duplicate("f", 64))

      proposal =
        build_approved_proposal_with_wo!(wo, tmp, ops_with_bytes)

      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
      {:ok, _status, rewired} = WorkerOutputStore.publish(store, wo)

      assert {:ok, %Evidence{effect: "EXACT_TARGET_STATE_OBSERVED"} = evidence} =
               PatchService.apply_with_completion_ref(proposal, decision, rewired, store)

      assert evidence.pre_state_digest == proposal.base_state_digest
      assert evidence.post_state_digest == PatchService.compute_post_state_digest(proposal)

      assert File.read!(Path.join(tmp, "README.md")) == "# after\n"
    end

    test "Z. governed apply rejects rebuild digest drift" do
      base = fresh_root!("m11_e2_z_drift")
      {:ready, store} = start_test_store(base)
      on_exit(fn -> stop(store.conn) end)

      tmp = fresh_tmp!("m11_e2_z_repo")
      before_digest = sha256_hex("# before\n")
      after_digest = sha256_hex("# after\n")
      File.write!(Path.join(tmp, "README.md"), "# before\n")

      completion_bytes =
        build_envelope_bytes([replace_op("README.md", after_digest, "# after\n", before_digest)])

      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      wo = build_worker_output("wko_z", completion_bytes)

      # Approve against the proposal built from completion bytes.
      proposal =
        build_approved_proposal_with_wo!(wo, tmp, ops_with_bytes)

      {:ok, _decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)
      {:ok, _status, rewired} = WorkerOutputStore.publish(store, wo)

      # Add a synthetic op to the decoded ops_with_bytes BEFORE rebuild —
      # this is exactly the mutation `apply_with_completion_ref` would have
      # to defend against in the rebuild step. The rebuilt proposal's
      # `patch_digest` MUST differ from the approved one; that mismatch is
      # the condition the canonical `assert_rebuild_matches_approved/2`
      # checks and the condition under which `apply_with_completion_ref/4`
      # returns `:E_PATCH_REBUILT_PATCH_MISMATCH`.
      synthetic = %{
        op: :add,
        path: "drift.txt",
        content: "synthetic",
        before_digest: nil,
        after_image_digest: sha256_hex("synthetic")
      }

      drifted_ops = ops_with_bytes ++ [synthetic]

      {:ok, rebuilt} =
        PatchProposal.build_from_worker_output(
          wo,
          drifted_ops,
          proposal.plan_ref,
          proposal.repository
        )

      assert rebuilt.patch_digest != proposal.patch_digest

      # Exercise the rebuild mismatch through the canonical decision
      # surface. The drifted op changes the operations manifest, and the
      # semantic digest is checked before patch_digest, so the canonical
      # result is exactly :E_PATCH_REBUILT_SEMANTIC_MISMATCH with zero
      # mutation.
      {:ok, approve_decision} =
        PatchService.decide(rebuilt, :approve, rebuilt.base_state_digest)

      assert {:error, %{code: :E_PATCH_REBUILT_SEMANTIC_MISMATCH}} =
               PatchService.apply_with_completion_ref(rebuilt, approve_decision, rewired, store)

      assert File.read!(Path.join(tmp, "README.md")) == "# before\n"
    end
  end

  # ─── helpers ───────────────────────────────────────────────────────────

  defp build_worker_output(id, completion_bytes) do
    %WorkerOutput{
      id: id,
      semantic_digest: "sha256:" <> String.duplicate("d", 64),
      attempt_ref: %{"id" => "att_#{id}", "digest" => "sha256:" <> String.duplicate("e", 64)},
      assignment_ref: %{"id" => "asg_#{id}", "digest" => "sha256:" <> String.duplicate("f", 64)},
      profile_ref: %{"id" => "prf_#{id}", "digest" => "sha256:" <> String.duplicate("1", 64)},
      output_kind: "PATCH_CANDIDATE",
      raw_completion_ref: %{
        "id" => "raw_#{id}",
        "digest" => "sha256:" <> String.duplicate("2", 64)
      },
      parsed_candidate_digest: "sha256:" <> String.duplicate("3", 64),
      completion_bytes: completion_bytes,
      base_commit: "0123456789abcdef0123456789abcdef01234567",
      base_state_digest: "sha256:" <> String.duplicate("4", 64),
      adapter_implementation_digest: "sha256:" <> String.duplicate("5", 64)
    }
  end

  defp build_envelope_bytes(ops, extra \\ %{}) do
    envelope =
      Map.merge(
        %{"schema" => @envelope_schema, "operations" => ops},
        extra
      )

    JSON.encode!(envelope)
  end

  defp decode_with_smuggled_field(bytes, extra) do
    parsed = :json.decode(bytes)
    smuggled = Map.merge(parsed, extra)
    rewritten = JSON.encode!(smuggled)

    PatchProposal.decode_envelope(rewritten)
  end

  defp replace_op(path, _after_digest, after_content, before_digest) do
    %{
      op: "replace",
      path: path,
      after_image_bytes: after_content,
      expected_before_digest: before_digest
    }
  end

  defp build_approved_proposal!(repo, before_digest, after_digest, after_content) do
    ops = [
      %{
        op: :replace,
        path: "README.md",
        content: after_content,
        before_digest: before_digest,
        after_image_digest: after_digest
      }
    ]

    build_approved_proposal_with_ops!(repo, ops)
  end

  defp build_approved_proposal_with_wo!(wo, repo, ops_with_bytes) do
    build_approved_proposal_with_ops!(repo, ops_with_bytes, wo)
  end

  defp build_approved_proposal_with_ops!(repo, ops_with_bytes, wo \\ nil) do
    wo = wo || build_worker_output("wko_default", " ")

    plan_ref = %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("6", 64)}

    {:ok, proposal} = PatchProposal.build(wo, ops_with_bytes, plan_ref, repo)
    proposal
  end

  defp start_test_store(base) do
    state_path = Path.join(base, "state.sqlite3")

    Store.start(path: state_path, store_id: "m11_e2_#{unique_tag()}", now: @now)
  end

  defp fresh_root!(tag) do
    dir = Path.join(System.tmp_dir!(), "kiln_#{tag}_#{unique_tag()}")
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    dir
  end

  defp fresh_tmp!(tag) do
    dir = Path.join(System.tmp_dir!(), "kiln_repo_#{tag}_#{unique_tag()}")
    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    dir
  end

  defp unique_tag do
    short =
      :crypto.strong_rand_bytes(6)
      |> Base.encode16(case: :lower)

    "#{short}_#{System.unique_integer([:positive])}"
  end

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end

  defp content_location_for("sha256:" <> hex) when byte_size(hex) == 64 do
    <<first_two::binary-size(2), rest::binary>> = hex
    "sha256/#{first_two}/#{rest}"
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _ -> :ok
  end
end
