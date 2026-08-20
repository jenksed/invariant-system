defmodule Kiln.WorkerDogfoodDispatchTest do
  @moduledoc """
  M3-R1 contract test: ordinary `Kiln.Worker.propose/5` invoked with
  `worker_provider_mode = :dogfood` returns a canonical bounded
  Worker Output whose `completion_bytes` are a real
  `engineering-system/implementer-patch-proposal-input/v1` envelope
  that decodes through `Kiln.PatchProposal.decode_envelope/1`.

  Authority rule: the Adapter is intelligence/capability — it does NOT
  authorize effects, write canonical workflow state, record verification
  as successful, manufacture review, create human acceptance, mark work
  complete, or directly mutate persistence. The Adapter emits a
  candidate only; canonical `human.decide` / `patch.apply` are the only
  paths that can authorize effects.

  This test pins:
    * `worker_provider_mode = :dogfood` is a recognized seam;
    * unknown modes fail closed (not silently masquerading as a valid mode);
    * the resulting Worker Output carries real bounded source-mutation
      bytes that round-trip through the canonical PatchProposal decoder;
    * the `adapter_implementation_digest` matches the DogfoodAdapter's
      own stable digest;
    * the `parsed_candidate_digest` is non-empty;
    * `completion_bytes` is text-only and bounded;
    * negative cases (missing task spec, invalid target, missing match)
      are rejected with bounded codes.
  """

  use ExUnit.Case, async: false

  alias Kiln.DogfoodAdapter
  alias Kiln.PatchProposal
  alias Kiln.Worker

  @fixture_root Path.join(System.tmp_dir!(), "kiln-worker-dogfood-#{System.unique_integer([:positive])}")

  setup do
    File.mkdir_p!(@fixture_root)
    # Initialize a real git repository so RepositoryObservation.observe/2
    # resolves a HEAD commit (the Worker requires head_resolved=true).
    System.cmd("git", ["init", "-q", "--initial-branch=main", @fixture_root])
    target = Path.join(@fixture_root, "bounded.ex")
    File.write!(
      target,
      "defmodule Bounded do\n  @moduledoc \"original\"\n  def hello, do: :ok\nend\n"
    )
    System.cmd("git", ["-C", @fixture_root, "-c", "user.name=Temper", "-c", "user.email=temper@local", "add", "."])
    System.cmd("git", ["-C", @fixture_root, "-c", "user.name=Temper", "-c", "user.email=temper@local", "commit", "-qm", "fixture"])

    previous_mode = Application.get_env(:kiln, :worker_provider_mode, :deterministic_fake)
    Application.put_env(:kiln, :worker_provider_mode, :dogfood)
    on_exit(fn ->
      Application.put_env(:kiln, :worker_provider_mode, previous_mode)
      File.rm_rf!(@fixture_root)
    end)

    {:ok, target: target, root: @fixture_root}
  end

  defp assignment_fixture do
    %{
      "schema" => "engineering-system/intelligence-assignment/m0-v1",
      "assignment_id" => "asg_test_dogfood",
      "requirement_ref" => %{
        "id" => "req_test",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      },
      "profile_ref" => %{
        "id" => "prof_test",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      },
      "eligibility_ref" => %{
        "id" => "elig_test",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      },
      "role" => "IMPLEMENTER",
      "selection_rule" => "FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST",
      "semantic_digest" => "sha256:" <> String.duplicate("b", 64)
    }
  end

  defp eligibility_fixture do
    %{
      "schema" => "test/eligibility/v0",
      "eligibility" => "QUALIFIED",
      "derived_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "valid_until" => DateTime.add(DateTime.utc_now(), 3600, :second) |> DateTime.to_iso8601(),
      "profile_ref" => %{"id" => "prof_test", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER"
    }
  end

  defp profile_fixture do
    profile_id = "prof_dogfood_test"
    semantic_digest = "sha256:" <> String.duplicate("a", 64)
    %{
      "schema" => "engineering-system/runtime-profile/m0-v1",
      "profile_id" => profile_id,
      "id" => profile_id,
      "semantic_digest" => semantic_digest,
      "system_config" => %{
        "id" => "sys_dogfood_test",
        "digest" => "sha256:" <> String.duplicate("b", 64)
      },
      "tool_policy" => %{
        "id" => "tool_dogfood_test",
        "digest" => "sha256:" <> String.duplicate("c", 64)
      }
    }
  end

  test "ordinary Worker.propose/5 with :dogfood emits canonical bounded worker output",
       %{target: target, root: root} do
    spec = %{
      "task_id" => "m3_first_dogfood_add_constant",
      "kind" => "add_attribute",
      "target" => Path.basename(target),
      "match" => "  @moduledoc \"original\"",
      "after" => "\n  @m3_dogfood_first_task \"bounded deterministic worker adapter — M3 dogfood\"",
      "rationale" => "M3 first-dogfood bounded source mutation"
    }

    request_attrs = %{
      "attempt_ref" => "att_test",
      "dogfood_task_spec" => spec
    }

    assert {:ok, worker_output} =
             Worker.propose(
               assignment_fixture(),
               eligibility_fixture(),
               profile_fixture(),
               request_attrs,
               root
             )

    # Canonical Worker Output shape
    assert worker_output.output_kind == "PATCH_CANDIDATE"
    assert is_binary(worker_output.semantic_digest)
    assert String.starts_with?(worker_output.semantic_digest, "sha256:")
    assert is_binary(worker_output.parsed_candidate_digest)
    assert String.starts_with?(worker_output.parsed_candidate_digest, "sha256:")
    assert is_binary(worker_output.completion_bytes)
    assert String.contains?(worker_output.completion_bytes, "@m3_dogfood_first_task")

    # adapter_implementation_digest matches the bound DogfoodAdapter.
    assert worker_output.adapter_implementation_digest ==
             DogfoodAdapter.implementation_digest()

    # Canonical PatchProposal decode round-trip succeeds.
    assert {:ok, ops} = PatchProposal.decode_envelope(worker_output.completion_bytes)
    assert length(ops) == 1
    [op] = ops
    assert op.op == :add
    assert op.path == Path.basename(target)
  end

  test "Worker.propose with :dogfood fails closed when task spec is missing",
       %{root: root} do
    request_attrs = %{"attempt_ref" => "att_test"}

    assert {:error, %{code: code}} =
             Worker.propose(
               assignment_fixture(),
               eligibility_fixture(),
               profile_fixture(),
               request_attrs,
               root
             )

    assert code == :E_DOGFOOD_TASK_SPEC_MISSING
  end

  test "Worker.propose with :dogfood fails closed on invalid target", %{root: root} do
    spec = %{
      "kind" => "add_attribute",
      "target" => "../escape.ex",
      "match" => "y",
      "after" => "z"
    }

    request_attrs = %{"attempt_ref" => "att_test", "dogfood_task_spec" => spec}

    assert {:error, %{code: code}} =
             Worker.propose(
               assignment_fixture(),
               eligibility_fixture(),
               profile_fixture(),
               request_attrs,
               root
             )

    assert code == :E_DOGFOOD_TARGET_INVALID
  end

  test "Worker.propose with :dogfood fails closed on missing match",
       %{target: target, root: root} do
    spec = %{
      "kind" => "add_attribute",
      "target" => Path.basename(target),
      "match" => "@nonexistent_marker",
      "after" => "\n  # appended"
    }

    request_attrs = %{"attempt_ref" => "att_test", "dogfood_task_spec" => spec}

    assert {:error, %{code: code}} =
             Worker.propose(
               assignment_fixture(),
               eligibility_fixture(),
               profile_fixture(),
               request_attrs,
               root
             )

    assert code == :E_DOGFOOD_MATCH_NOT_FOUND
  end

  describe "worker_provider_mode semantics" do
    test "absent configuration defaults to :deterministic_fake" do
      Application.delete_env(:kiln, :worker_provider_mode)
      assert Worker.worker_provider_mode() == :deterministic_fake
    end

    test "explicitly set :deterministic_fake is honored" do
      Application.put_env(:kiln, :worker_provider_mode, :deterministic_fake)
      assert Worker.worker_provider_mode() == :deterministic_fake
    end

    test "explicitly set :dogfood is honored" do
      Application.put_env(:kiln, :worker_provider_mode, :dogfood)
      assert Worker.worker_provider_mode() == :dogfood
    end

    test "explicitly set :real_provider is honored" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      assert Worker.worker_provider_mode() == :real_provider
    end

    test "explicitly invalid mode fails closed (no silent fallback to :deterministic_fake)" do
      Application.put_env(:kiln, :worker_provider_mode, :something_unknown)

      assert {:error, %{code: :E_WORKER_PROVIDER_MODE_INVALID}} =
               Worker.worker_provider_mode()
    end

    test "nil is treated as a missing key, not as a value to validate" do
      Application.put_env(:kiln, :worker_provider_mode, nil)
      assert Worker.worker_provider_mode() == :deterministic_fake
    end

    test "Worker.propose with explicit invalid mode returns the bounded error", %{root: root} do
      Application.put_env(:kiln, :worker_provider_mode, :something_unknown)

      request_attrs = %{
        "attempt_ref" => "att_test",
        "dogfood_task_spec" => %{
          "kind" => "add_attribute",
          "target" => "bounded.ex",
          "match" => "  @moduledoc \"original\"",
          "after" => "\n  @m3_dogfood_first_task \"x\""
        }
      }

      assert {:error, %{code: :E_WORKER_PROVIDER_MODE_INVALID}} =
               Worker.propose(
                 assignment_fixture(),
                 eligibility_fixture(),
                 profile_fixture(),
                 request_attrs,
                 root
               )
    end
  end
end