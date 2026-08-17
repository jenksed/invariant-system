defmodule Kiln.Verification.Registry do
  @moduledoc """
  Static registry for Wave 6 verification commands.

  A caller selects an identity; it never supplies executable policy. Every
  field in the Plan is compared with this Kiln-owned record before spawn.
  """

  defmodule Command do
    @moduledoc false
    @enforce_keys [:id, :executable, :argv, :cwd, :timeout_ms, :proves, :registration_digest]
    defstruct @enforce_keys
  end

  @commands %{
    "arsenal.method-record" => {"project-arsenal", "python3", ["scripts/test-method-record.py"]},
    "arsenal.method-evaluation" =>
      {"project-arsenal", "python3", ["scripts/test-arsenal-evaluate.py"]},
    "arsenal.wave5-benchmark" =>
      {"project-arsenal", "python3", ["scripts/test-wave5-recon-bench.py"]},
    "arsenal.capability-contract" =>
      {"project-arsenal", "python3", ["scripts/test-capability-contract.py"]},
    "arsenal.compiler" => {"project-arsenal", "python3", ["scripts/test-arsenal-compiler.py"]},
    "arsenal.trust" => {"project-arsenal", "python3", ["scripts/test-arsenal-trust.py"]},
    "arsenal.adapter" =>
      {"project-arsenal", "python3", ["scripts/test-repository-recon-adapter.py"]},
    "loadout.format" => {"loadout", "npm", ["run", "format:check"]},
    "loadout.lint" => {"loadout", "npm", ["run", "lint"]},
    "loadout.typecheck" => {"loadout", "npm", ["run", "typecheck"]},
    "loadout.test" => {"loadout", "npm", ["test"]},
    "loadout.contracts" => {"loadout", "node", ["dist/cli.js", "validate-contracts"]},
    "loadout.build" => {"loadout", "npm", ["run", "build"]},
    "loadout.built-cli-smoke" => {"loadout", "node", ["dist/cli.js", "validate-contracts"]},
    "loadout.worktree-regression" =>
      {"loadout", "npm", ["test", "--", "tests/unit/workspace.snapshot.spec.ts"]},
    "kiln.preflight" => {"kiln", "scripts/agent-preflight", []},
    "kiln.preflight-tests" => {"kiln", "scripts/test-agent-preflight", []},
    "kiln.agent-assets" => {"kiln", "scripts/validate-agent-assets", []},
    "kiln.format" => {"kiln", "mix", ["format", "--check-formatted"]},
    "kiln.compile" => {"kiln", "mix", ["compile", "--warnings-as-errors"]},
    "kiln.xref" =>
      {"kiln", "mix",
       [
         "xref",
         "graph",
         "--format",
         "cycles",
         "--label",
         "compile-connected",
         "--fail-above",
         "0"
       ]},
    "kiln.test" => {"kiln", "mix", ["test"]},
    "kiln.migrations" => {"kiln", "mix", ["test", "test/kiln/store/migrations_test.exs"]},
    "kiln.restart-regression" =>
      {"kiln", "mix", ["test", "test/kiln/supervision_restart_regression_test.exs"]},
    "kiln.cli-smoke" => {"kiln", "mix", ["test", "test/kiln/cli/ready_store_test.exs"]},
    "temper.typecheck" => {"temper", "npm", ["run", "typecheck"]},
    "temper.test" => {"temper", "npm", ["test"]},
    "temper.build" => {"temper", "npm", ["run", "build"]},
    "temper.interactive-smoke" =>
      {"temper", "node",
       ["--test", "dist/test/workbench.test.js", "--test-name-pattern", "interactive"]}
  }

  @spec validate(map(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def validate(command, repository, base_commit) when is_map(command) do
    id = command["command_id"]
    profile = Path.basename(repository)

    expected =
      if id == "repo.diff-check" do
        {profile, "git", ["diff", "--check", base_commit, "--"]}
      else
        Map.get(@commands, id)
      end

    with {expected_profile, executable, argv} when not is_nil(expected_profile) <- expected,
         true <- profile_match?(expected_profile, profile),
         true <- command["executable"] == executable,
         true <- command["argv"] == argv,
         true <- command["working_directory"] == ".",
         true <- command["environment_policy"] == "minimal-toolchain-path",
         true <- command["network_policy"] == "not-required",
         true <- command["mutation_expectation"] in ["none", "derived-data-only"],
         timeout when is_integer(timeout) and timeout > 0 and timeout <= 600_000 <-
           command["timeout_ms"],
         proves when is_list(proves) and proves != [] <- command["proves"] do
      {:ok,
       %Command{
         id: id,
         executable: executable,
         argv: argv,
         cwd: repository,
         timeout_ms: timeout,
         proves: proves,
         registration_digest: registration_digest(id, executable, argv, expected_profile)
       }}
    else
      nil -> {:error, {:unregistered_command, id}}
      false -> {:error, {:command_registration_mismatch, id}}
      _ -> {:error, {:invalid_command_registration, id}}
    end
  end

  def validate(command, _repository, _base_commit),
    do: {:error, {:invalid_command_registration, command}}

  # The invariant-system monorepo hosts Arsenal at products/arsenal, so the
  # repository basename "arsenal" is the same profile as the historical
  # standalone checkout name "project-arsenal". Registration digests continue
  # to be computed over the canonical expected profile.
  defp profile_match?(expected_profile, profile) do
    expected_profile == profile or
      (expected_profile == "project-arsenal" and profile == "arsenal")
  end

  defp registration_digest(id, executable, argv, profile) do
    bytes =
      Kiln.Store.Canonical.encode(%{
        "command_id" => id,
        "executable" => executable,
        "argv" => argv,
        "repository_profile" => profile
      })

    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end
end
