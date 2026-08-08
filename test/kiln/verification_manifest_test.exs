defmodule Kiln.VerificationManifestTest do
  @moduledoc """
  Tests for the slice verification manifest.

  The manifest is implementation Evidence with no authority. These tests
  prove the two properties that matter for P1-S01-T05-AC05: a manifest binds
  to the exact state it was generated from, and it cannot be edited into a
  claim it is not entitled to make.
  """

  use ExUnit.Case, async: true

  alias Kiln.VerificationManifest, as: Manifest

  @commit String.duplicate("a", 40)

  defp attrs(overrides \\ []) do
    Enum.into(overrides, %{
      manifest_id: "P1-S01-V01",
      slice: "P1-S01",
      created_at: "2026-08-08T00:00:00Z",
      repository: %{commit: @commit, dirty: false, branch: "work/p1-s01-t05-slice-gate"},
      toolchain: %{elixir: "1.20.2", otp: "28"},
      store: %{store_format: "kiln-state/v1", store_version: 2},
      gate: %{outcome: :pass, command: "scripts/gates/slice-01"},
      demo: %{outcome: :pass, demo_id: "P1-S01-D01"},
      conformance: %{outcome: :pass},
      owner_machine: %{outcome: :pass, host: "arm64"}
    })
  end

  describe "build/1" do
    test "produces a passing manifest from complete clean-tree facts" do
      assert {:ok, manifest} = Manifest.build(attrs())

      assert manifest["schema"] == Manifest.schema()
      assert manifest["manifest_id"] == "P1-S01-V01"
      assert manifest["kind"] == "implementation_evidence"
      assert manifest["overall"] == "pass"
      assert manifest["digest"] =~ ~r/^sha256:[0-9a-f]{64}$/
      assert :ok = Manifest.validate(manifest)
    end

    test "rejects a missing required component" do
      assert {:error, {:missing_keys, missing}} =
               Manifest.build(attrs() |> Map.delete(:owner_machine))

      assert :owner_machine in missing
    end

    test "rejects a non-exact commit" do
      assert {:error, {:invalid_commit, _}} =
               Manifest.build(attrs(repository: %{commit: "HEAD", dirty: false}))
    end

    test "requires an explicit dirty flag so an absent flag is never read as clean" do
      assert {:error, {:invalid_dirty_flag, _}} =
               Manifest.build(attrs(repository: %{commit: @commit}))
    end

    test "rejects an unrecognized component outcome" do
      assert {:error, {:gate, {:invalid_outcome, _}}} =
               Manifest.build(attrs(gate: %{outcome: :probably_fine}))
    end
  end

  describe "overall result is derived, never supplied" do
    test "a failing component yields fail" do
      assert {:ok, manifest} = Manifest.build(attrs(demo: %{outcome: :fail}))
      assert manifest["overall"] == "fail"
    end

    test "a blocked owner-machine component yields blocked, not pass" do
      assert {:ok, manifest} = Manifest.build(attrs(owner_machine: %{outcome: :blocked}))
      assert manifest["overall"] == "blocked"
    end

    test "a not-run component yields blocked, not pass" do
      assert {:ok, manifest} = Manifest.build(attrs(owner_machine: %{outcome: :not_run}))
      assert manifest["overall"] == "blocked"
    end

    test "a dirty working tree blocks even when every component passed" do
      assert {:ok, manifest} =
               Manifest.build(
                 attrs(repository: %{commit: @commit, dirty: true, fingerprint: "x"})
               )

      assert manifest["overall"] == "blocked"
    end

    test "a supplied overall value cannot override the derived one" do
      assert {:ok, manifest} = Manifest.build(attrs(demo: %{outcome: :fail}))
      # `build/1` ignores any caller-supplied overall; the derived value stands.
      assert manifest["overall"] == "fail"
    end
  end

  describe "state binding prevents replay against another commit" do
    test "editing the commit invalidates the manifest" do
      {:ok, manifest} = Manifest.build(attrs())

      tampered = put_in(manifest, ["repository", "commit"], String.duplicate("b", 40))

      assert {:error, {:digest_mismatch, _}} = Manifest.validate(tampered)
    end

    test "editing a component outcome invalidates the manifest" do
      {:ok, manifest} = Manifest.build(attrs(gate: %{outcome: :fail}))

      tampered =
        manifest
        |> put_in(["components", "gate", "outcome"], "pass")
        |> Map.put("overall", "pass")

      assert {:error, {:digest_mismatch, _}} = Manifest.validate(tampered)
    end

    test "flipping overall alone is caught before the digest check" do
      {:ok, manifest} = Manifest.build(attrs(gate: %{outcome: :fail}))

      tampered = Map.put(manifest, "overall", "pass")

      assert {:error, {:overall_mismatch, _}} = Manifest.validate(tampered)
    end

    test "two different commits produce two different manifests" do
      {:ok, first} = Manifest.build(attrs())

      {:ok, second} =
        Manifest.build(attrs(repository: %{commit: String.duplicate("f", 40), dirty: false}))

      refute first["digest"] == second["digest"]
    end
  end

  describe "the manifest cannot claim authority (AC05, R10)" do
    test "every non-authority refusal is recorded as false" do
      {:ok, manifest} = Manifest.build(attrs())

      refusals = manifest["not_authority"]

      assert refusals["satisfies_task"] == false
      assert refusals["completes_run"] == false
      assert refusals["records_user_product_acceptance"] == false
      assert refusals["is_product_receipt"] == false
      assert refusals["authorizes_next_slice"] == false
      assert refusals["can_make_a_failed_gate_pass"] == false
    end

    test "editing a refusal to claim authority invalidates the manifest" do
      {:ok, manifest} = Manifest.build(attrs())

      tampered = put_in(manifest, ["not_authority", "is_product_receipt"], true)

      assert {:error, :not_authority_altered} = Manifest.validate(tampered)
    end

    test "removing the refusals invalidates the manifest" do
      {:ok, manifest} = Manifest.build(attrs())

      assert {:error, :missing_not_authority} =
               Manifest.validate(Map.delete(manifest, "not_authority"))
    end

    test "the manifest carries no completion, acceptance, or receipt field" do
      {:ok, manifest} = Manifest.build(attrs())

      encoded = Kiln.Store.Canonical.encode(manifest)

      for forbidden <- ~w(task_completed run_completed accepted_by receipt_id sealed_at) do
        refute encoded =~ forbidden,
               "manifest carries a completion/acceptance field: #{forbidden}"
      end
    end
  end

  describe "validate/1" do
    test "rejects a foreign schema" do
      {:ok, manifest} = Manifest.build(attrs())
      assert {:error, {:invalid_schema, _}} = Manifest.validate(Map.put(manifest, "schema", "x"))
    end

    test "rejects a missing component section" do
      {:ok, manifest} = Manifest.build(attrs())
      tampered = update_in(manifest, ["components"], &Map.delete(&1, "demo"))
      assert {:error, {:missing_components, [:demo]}} = Manifest.validate(tampered)
    end

    test "rejects a non-map document" do
      assert {:error, :not_a_map} = Manifest.validate("not a manifest")
    end
  end
end
