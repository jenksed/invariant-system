defmodule Kiln.IntegrationHygieneRegressionTest do
  @moduledoc """
  M4-Q1C integration-hygiene regression guard.

  Three narrow invariants proven by this test:

    A. LIFECYCLE-FIXTURE-SOURCE-SHAPE
       The M3-Dogfood lifecycle fixture must not use
       `Path.expand("../support", File.cwd!())` — that pattern
       previously contaminated the source checkout with a nested
       `.git`. The lifecycle test must anchor its disposable Git
       repository under the per-test tmp dir provided by `setup/1`.

    B. SOURCE-CHECKOUT-ISOLATION
       The monorepo must contain no nested `.git` directory anywhere
       below `products/`. The lifecycle fixture's on_exit cleanup
       must keep the source checkout untouched.

    C. TEMPER.CELLFRAME SINGLE OWNER
       Exactly one source definition of `Temper.CellFrame` exists
       below `products/`, and that definition lives in
       `products/temper-elixir/lib/temper/cell_frame.ex`. A second
       copy under `products/kiln/lib/temper/cell_frame.ex` would
       emit a BEAM "redefining module Temper.CellFrame" warning when
       the temper-elixir product (which depends on kiln) is
       compiled.

  This module is independent-source-only and does not depend on any
   other test module being loaded.

  Path discipline: paths are derived from `__DIR__` (the directory
   containing this test file) so the assertions are robust regardless
   of which directory `mix test` is invoked from. Do NOT use
   `File.cwd!()` for sibling or repo-root discovery in this module.
  """

  use ExUnit.Case, async: true

  @repo_root Path.expand("../../../../", __DIR__)

  describe "lifecycle fixture source shape (A)" do
    test "lifecycle test does not couple to a sibling products/<x> checkout" do
      lifecycle_path = Path.join(__DIR__, "m3_dogfood_lifecycle_test.exs")
      source = File.read!(lifecycle_path)

      # The historical bug used `File.cwd!()` as the anchor for
      # Path.expand, which landed the disposable repo under
      # products/support/ when invoked from products/kiln.
      refute source =~ ~r/Path\.expand\(\s*["']\.\.\/support/,
             "lifecycle test must not use Path.expand('../support', ...)"

      # The repaired pattern anchors under the per-test dir provided
      # by setup/1.
      assert source =~ "disposable_repo_path(dir)",
             "lifecycle test must anchor disposable repos under setup dir"
    end
  end

  describe "source-checkout isolation (B)" do
    test "no nested .git directory exists below products/" do
      nested = find_nested_git(@repo_root)
      assert nested == [],
             "expected no nested .git under products/, found: #{inspect(nested)}"
    end
  end

  describe "Temper.CellFrame single owner (C)" do
    test "exactly one Temper.CellFrame source exists and is owned by temper-elixir" do
      products_root = Path.join(@repo_root, "products")
      sources = find_cell_frame_sources(products_root)

      assert sources == ["products/temper-elixir/lib/temper/cell_frame.ex"],
             "expected exactly one Temper.CellFrame source owned by " <>
               "products/temper-elixir, found: #{inspect(sources)}"

      refute File.exists?(Path.join(products_root, "kiln/lib/temper/cell_frame.ex")),
             "products/kiln must not own a Temper.CellFrame implementation"
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
      rel = Path.relative_to(abs, @repo_root)
      # Normalize to forward slashes so the assertion is stable
      # across platforms.
      String.replace(rel, "\\", "/")
    end)
    |> Enum.sort()
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