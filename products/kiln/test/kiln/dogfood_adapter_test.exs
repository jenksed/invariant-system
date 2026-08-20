defmodule Kiln.DogfoodAdapterTest do
  @moduledoc """
  M3 first-dogfood bounded deterministic worker adapter tests.

  These tests prove the bounded source-mutation path without ever
  touching a real network provider. The Adapter is the foundation of
  the M3 natural chain — without it, the bounded
  `engineering-system/implementer-patch-proposal-input/v1` envelope
  cannot be produced without external credentials.
  """

  use ExUnit.Case, async: true

  alias Kiln.DogfoodAdapter
  alias Kiln.PatchProposal

  @fixture_root Path.join(System.tmp_dir!(), "kiln-dogfood-fixture-#{System.unique_integer([:positive])}")

  setup do
    File.mkdir_p!(@fixture_root)
    target = Path.join(@fixture_root, "bounded.ex")
    File.write!(target, "defmodule Bounded do\n  @moduledoc \"original\"\nend\n")
    on_exit(fn -> File.rm_rf!(@fixture_root) end)
    {:ok, target: target, root: @fixture_root}
  end

  test "builds a canonical add envelope and decodes through the bounded validator",
       %{target: target, root: root} do
    spec = %{
      "task_id" => "m3_first_dogfood_add_constant",
      "kind" => "add_attribute",
      "target" => Path.basename(target),
      "match" => "  @moduledoc \"original\"",
      "after" => "\n  @m3_dogfood_first_task \"added\"",
      "rationale" => "bounded self-referential change"
    }

    assert {:ok, bytes, digest} = DogfoodAdapter.build_envelope(spec, root)
    assert is_binary(bytes)
    assert String.starts_with?(digest, "sha256:")

    # The emitted bytes round-trip through the canonical PatchProposal
    # decoder — the canonical contract is exercised end-to-end.
    assert {:ok, ops} = PatchProposal.decode_envelope(bytes)
    assert length(ops) == 1
    [op] = ops
    assert op.op == :add
    assert op.path == Path.basename(target)
    assert String.contains?(op.content, "@m3_dogfood_first_task")
  end

  test "rejects spec without kind", %{root: root} do
    spec = %{"target" => "x.ex", "match" => "y", "after" => "z"}
    assert {:error, %{code: :E_DOGFOOD_KIND_MISSING}} =
             DogfoodAdapter.build_envelope(spec, root)
  end

  test "rejects unknown kind", %{root: root} do
    spec = %{"kind" => "magic", "target" => "x.ex", "match" => "y", "after" => "z"}
    assert {:error, %{code: :E_DOGFOOD_KIND_INVALID}} =
             DogfoodAdapter.build_envelope(spec, root)
  end

  test "rejects target outside repository root", %{root: root} do
    spec = %{
      "kind" => "add_attribute",
      "target" => "../escape.ex",
      "match" => "y",
      "after" => "z"
    }

    assert {:error, %{code: :E_DOGFOOD_TARGET_INVALID}} =
             DogfoodAdapter.build_envelope(spec, root)
  end

  test "rejects target in .git/", %{root: root} do
    spec = %{
      "kind" => "add_attribute",
      "target" => ".git/config",
      "match" => "y",
      "after" => "z"
    }

    assert {:error, %{code: :E_DOGFOOD_TARGET_INVALID}} =
             DogfoodAdapter.build_envelope(spec, root)
  end

  test "rejects when match string does not occur", %{target: target, root: root} do
    spec = %{
      "kind" => "add_attribute",
      "target" => Path.basename(target),
      "match" => "@nonexistent_marker",
      "after" => "\n  # appended"
    }

    assert {:error, %{code: :E_DOGFOOD_MATCH_NOT_FOUND}} =
             DogfoodAdapter.build_envelope(spec, root)
  end
end