defmodule Kiln.Verification.RegistryPathsTest do
  use ExUnit.Case, async: true

  alias Kiln.Verification.Registry

  test "the dead arsenal.wave6-benchmark entry is not present (RISK B repair)" do
    ids =
      Registry.module_info(:attributes)
      |> Keyword.get_values(:commands)
      |> List.flatten()
      |> case do
        %{} = m -> Map.keys(m)
        other -> other
      end

    refute "arsenal.wave6-benchmark" in ids,
           "RISK B regression: arsenal.wave6-benchmark entry should have been removed"
  end

  test "validate/3 rejects the dead arsenal.wave6-benchmark command id" do
    command = %{
      "command_id" => "arsenal.wave6-benchmark",
      "executable" => "python3",
      "argv" => ["scripts/test-wave6-verify-bench.py"],
      "working_directory" => ".",
      "environment_policy" => "minimal-toolchain-path",
      "network_policy" => "not-required",
      "mutation_expectation" => "none",
      "timeout_ms" => 60_000,
      "proves" => ["wave6"]
    }

    assert {:error, {:unregistered_command, "arsenal.wave6-benchmark"}} =
             Registry.validate(command, "/tmp", "deadbeef")
  end
end