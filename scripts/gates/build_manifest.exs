# P1-S01-V01 slice verification manifest generator.
#
# Invoked by `scripts/gates/slice-01` through `mix run --no-start`. It reads
# the gate's collected facts from the environment, builds the manifest through
# `Kiln.VerificationManifest`, validates it, and writes both the structured
# gate result and the manifest to the artifact path.
#
# The manifest is implementation Evidence. It carries no authority: the module
# encodes that refusal as data and `validate/1` rejects a document whose
# refusals were altered.

defmodule Kiln.Gates.BuildManifest do
  alias Kiln.VerificationManifest, as: Manifest

  def run do
    components = JSON.decode!(env!("KILN_GATE_COMPONENTS"))
    result_path = env!("KILN_GATE_RESULT_PATH")

    repository = %{
      commit: env!("KILN_GATE_COMMIT"),
      branch: env!("KILN_GATE_BRANCH"),
      dirty: env!("KILN_GATE_DIRTY") == "true",
      dirty_fingerprint: env!("KILN_GATE_DIRTY_FINGERPRINT")
    }

    toolchain = %{
      elixir: env!("KILN_GATE_ELIXIR"),
      otp: env!("KILN_GATE_OTP"),
      git: env!("KILN_GATE_GIT"),
      exqlite: to_string(Application.spec(:exqlite, :vsn) || "unknown"),
      host_os: env!("KILN_GATE_HOST_OS"),
      host_arch: env!("KILN_GATE_HOST_ARCH"),
      host_kernel: env!("KILN_GATE_HOST_KERNEL"),
      hw_model: hw_model()
    }

    store = %{
      store_format: Kiln.Store.store_format(),
      migration_count: String.to_integer(env!("KILN_GATE_MIGRATION_COUNT")),
      migration_fingerprint: env!("KILN_GATE_MIGRATION_FINGERPRINT"),
      fixture_fingerprint: env!("KILN_GATE_FIXTURE_FINGERPRINT")
    }

    gate_outcome = env!("KILN_GATE_OUTCOME")
    owner_outcome = env!("KILN_GATE_OWNER_OUTCOME")

    demo_outcome = component_outcome(components, "p1_s01_d01_demo")

    # Conformance is the aggregate of the Repository-conformance and
    # build-integrity components. A single non-passing component downgrades it;
    # `not_applicable` is the one accepted non-pass (P0-W32's trunk rule).
    conformance_outcome =
      components
      |> Enum.reject(&(&1["name"] in ["p1_s01_d01_demo", "owner_machine_diagnostic"]))
      |> aggregate_outcome()

    attrs = %{
      manifest_id: env!("KILN_GATE_MANIFEST_ID"),
      slice: env!("KILN_GATE_SLICE"),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      repository: repository,
      toolchain: toolchain,
      store: store,
      tickets: tickets(),
      gate: %{
        outcome: gate_outcome,
        command: "scripts/gates/slice-01",
        component_count: length(components),
        components: components
      },
      demo: %{
        outcome: demo_outcome,
        demo_id: "P1-S01-D01",
        command: "scripts/demos/p1-s01"
      },
      conformance: %{outcome: conformance_outcome},
      owner_machine: %{
        outcome: owner_outcome,
        decision: "OD-02",
        command: "scripts/diagnostics/p1-s01-store-host"
      },
      warnings: warnings(owner_outcome, repository),
      exclusions: exclusions(),
      unknowns: unknowns(owner_outcome)
    }

    case Manifest.build(attrs) do
      {:ok, manifest} ->
        case Manifest.validate(manifest) do
          :ok -> write!(result_path, manifest)
          {:error, reason} -> abort("manifest failed validation: #{inspect(reason)}")
        end

      {:error, reason} ->
        abort("manifest could not be built: #{inspect(reason)}")
    end
  end

  defp write!(path, manifest) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, JSON.encode!(manifest))

    IO.puts("  manifest: #{manifest["manifest_id"]}")
    IO.puts("  overall: #{manifest["overall"]}")
    IO.puts("  digest: #{manifest["digest"]}")
    IO.puts("  written: #{path}")
  end

  # `not_applicable` does not downgrade the aggregate: P0-W32 accepted that the
  # governing-plan preflight is a pull-request property. Anything else that is
  # not a pass does downgrade it, so a blocked control can never read as pass.
  defp aggregate_outcome(components) do
    outcomes = Enum.map(components, & &1["outcome"])

    cond do
      Enum.any?(outcomes, &(&1 == "fail")) -> "fail"
      Enum.any?(outcomes, &(&1 == "blocked")) -> "blocked"
      Enum.all?(outcomes, &(&1 in ["pass", "not_applicable"])) -> "pass"
      true -> "blocked"
    end
  end

  defp component_outcome(components, name) do
    case Enum.find(components, &(&1["name"] == name)) do
      %{"outcome" => outcome} -> outcome
      nil -> "not_run"
    end
  end

  defp tickets do
    [
      %{id: "P1-S01-T01", subject: "domain foundation"},
      %{id: "P1-S01-T02", subject: "durable store"},
      %{id: "P1-S01-T03", subject: "replay and projections"},
      %{id: "P1-S01-T06", subject: "workflow application boundary"},
      %{id: "P1-S01-T04", subject: "foundation CLI"},
      %{id: "P1-S01-T05", subject: "slice gate, demo, and manifest"}
    ]
  end

  defp warnings(owner_outcome, repository) do
    []
    |> maybe(owner_outcome != "pass", "owner-machine (OD-02) Evidence is #{owner_outcome}")
    |> maybe(repository.dirty, "the working tree was dirty; the manifest does not describe a committed state")
  end

  defp unknowns(owner_outcome) do
    maybe(
      [],
      owner_outcome != "pass",
      "OD-02 host filesystem, WAL, and sync behavior is unverified at this state"
    )
  end

  defp exclusions do
    [
      "provider and fake-provider execution",
      "Repository source read beyond accepted metadata",
      "Context runtime and model-facing Tools",
      "Patch engine and source mutation",
      "external registered Command execution and the process-group helper",
      "criterion completion Evidence and product Receipt",
      "release packaging",
      "Child Runs, TUI, and Wave B behavior",
      "P1-S02 authorization"
    ]
  end

  defp maybe(list, false, _item), do: list
  defp maybe(list, true, item), do: list ++ [item]

  defp hw_model do
    case System.fetch_env("KILN_GATE_HOST_MODEL") do
      {:ok, value} -> value
      :error -> "unknown"
    end
  end

  defp env!(name) do
    case System.fetch_env(name) do
      {:ok, value} -> value
      :error -> abort("required gate fact #{name} is not set")
    end
  end

  defp abort(message) do
    IO.puts(:stderr, "build_manifest: #{message}")
    System.halt(1)
  end
end

Kiln.Gates.BuildManifest.run()
