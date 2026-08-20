defmodule Kiln.IntegrationHygieneRegressionTest do
  @moduledoc """
  M4-Q1C integration-hygiene regression guard.

  Two narrow invariants proven by this test:

    1. SOURCE-CHECKOUT-ISOLATION
       The M3-Dogfood lifecycle fixture creates a real disposable
       Git repository. It MUST be created under System.tmp_dir!/0
       (or another per-invocation temp location) and MUST NOT leave
       a `.git` directory under any `products/*/` path.

    2. TEMPER.CELLFRAME SINGLE OWNER
       The pure-Elixir `Temper.CellFrame` rendering module has
       exactly one source owner. A second copy under
       `products/kiln/lib/temper/cell_frame.ex` would re-emit the
       BEAM "redefining module Temper.CellFrame" warning when the
       temper-elixir product (which depends on kiln) is compiled.

  These properties are checked structurally against the source tree
  at evaluation time. They do not depend on a previous test run.
  """

  use ExUnit.Case, async: true

  alias Kiln.M3DogfoodLifecycleTest

  defp monorepo_root do
    # The monorepo root contains the products/ directory. From the
    # Kiln test working directory (products/kiln), ascend two levels.
    Path.expand("../../..", File.cwd!())
  end

  describe "source-checkout isolation" do
    test "no products/* path is created by the fixture setup" do
      # The m3_dogfood_lifecycle_test.exs fixture uses
      # System.tmp_dir!/0 via the setup/1 dir. The disposable_repo_path/1
      # helper joins onto that dir. There must be no hard-coded path
      # outside System.tmp_dir!/0 (or similar) that lands inside
      # the source checkout.
      #
      # We assert this by reading the test source and confirming
      # the only path under products/ used by the fixture is via
      # the bounded Store path (already proven isolated).
      source =
        File.read!(Path.expand("./m3_dogfood_lifecycle_test.exs", File.cwd!()))

      refute source =~ ~r/Path\.expand\(\s*["']\.\.\/support/
      refute source =~ ~r/File\.mkdir_p!\(\s*["']products\//

      # The bounded test must use the setup/1 dir, not File.cwd!().
      assert source =~ "disposable_repo_path(dir)"
    end

    test "disposable_repo_path/1 anchors under the setup dir, not under products/" do
      assert function_exported?(M3DogfoodLifecycleTest, :__info__, 1)

      # The disposable repo path is private; we can only verify it
      # indirectly via the source text. Confirm no Path.expand
      # target resolves under the source checkout.
      source =
        File.read!(Path.expand("./m3_dogfood_lifecycle_test.exs", File.cwd!()))

      # No "Path.expand('../support', File.cwd!())" — the bug.
      refute source =~ ~r/Path\.expand\(\s*["']\.\.\/support/
    end

    test "products/ tree contains no nested .git directories" do
      root = monorepo_root()
      nested =
        root
        |> Path.join("products")
        |> then(fn products_root ->
          case File.ls(products_root) do
            {:ok, entries} ->
              Enum.flat_map(entries, fn entry ->
                path = Path.join(products_root, entry)
                case File.ls(path) do
                  {:ok, _} -> find_nested_git(path)
                  _ -> []
                end
              end)

            _ ->
              []
          end
        end)

      assert nested == [],
             "expected no nested .git under products/, found: #{inspect(nested)}"
    end
  end

  describe "Temper.CellFrame single owner" do
    test "exactly one source definition of Temper.CellFrame exists" do
      root = monorepo_root()

      defs =
        root
        |> Path.join("products")
        |> then(&find_cell_frame_sources/1)

      assert length(defs) == 1,
             "expected exactly 1 Temper.CellFrame source, found: #{inspect(defs)}"
    end

    test "Temper.CellFrame lives under products/temper-elixir" do
      root = monorepo_root()

      defs =
        root
        |> Path.join("products")
        |> then(&find_cell_frame_sources/1)

      assert defs == ["products/temper-elixir/lib/temper/cell_frame.ex"],
             "expected owner to be products/temper-elixir, found: #{inspect(defs)}"
    end

    test "products/kiln does not own any Temper.* source under its lib/" do
      root = monorepo_root()
      kiln_lib = Path.join([root, "products", "kiln", "lib", "temper"])

      kiln_temper_sources =
        case File.ls(kiln_lib) do
          {:ok, entries} -> Enum.map(entries, &Path.join("products/kiln/lib/temper", &1))
          _ -> []
        end

      assert kiln_temper_sources == [],
             "Kiln must not own Temper rendering implementation; found: #{inspect(kiln_temper_sources)}"
    end
  end

  # ---- helpers ----

  defp find_nested_git(dir) do
    case File.ls(dir) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry ->
          path = Path.join(dir, entry)

          cond do
            entry == ".git" -> [path]
            File.dir?(path) -> find_nested_git(path)
            true -> []
          end
        end)

      _ ->
        []
    end
  end

  defp find_cell_frame_sources(products_root) do
    collect_files(products_root, "cell_frame.ex")
    |> Enum.map(fn abs ->
      abs
      |> Path.relative_to(products_root)
      |> Path.dirname()
      |> then(&Path.join(&1, "cell_frame.ex"))
    end)
  end

  defp collect_files(root, target_name, acc \\ []) do
    case File.ls(root) do
      {:ok, entries} ->
        Enum.reduce(entries, acc, fn entry, acc ->
          path = Path.join(root, entry)

          cond do
            entry == target_name -> [path | acc]
            File.dir?(path) -> collect_files(path, target_name, acc)
            true -> acc
          end
        end)

      _ ->
        acc
    end
  end
end