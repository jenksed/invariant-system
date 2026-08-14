defmodule Kiln.Verification.CommandHostTest do
  use ExUnit.Case, async: false

  alias Kiln.Verification.{CommandHost, Registry}

  test "runs exact argv without a shell and captures separate output" do
    repository = repository!()
    base = git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    request = %{
      "command_id" => "repo.diff-check",
      "executable" => "git",
      "argv" => ["diff", "--check", base, "--"],
      "working_directory" => ".",
      "timeout_ms" => 30_000,
      "environment_policy" => "minimal-toolchain-path",
      "network_policy" => "not-required",
      "mutation_expectation" => "none",
      "proves" => ["patch-hygiene"],
      "rationale" => "test"
    }

    assert {:ok, command} = Registry.validate(request, repository, base)
    assert {:ok, result} = CommandHost.run(command)
    assert result.result == :pass
    assert result.exit_code == 0
    assert result.stdout == ""
    assert result.stderr == ""
    refute result.timed_out
  end

  test "forwards TMPDIR to spawned child processes as the per-command scratch directory" do
    repository = repository!()
    command = tmpdir_echo_command(repository)

    scratch_root =
      Path.join(
        System.tmp_dir!(),
        "kiln-cmd-host-tmpdir-forwarding-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(scratch_root)
    on_exit(fn -> File.rm_rf(scratch_root) end)

    assert {:ok, result} = CommandHost.run(command, temp_dir: scratch_root)
    assert result.result == :pass

    trimmed = String.trim(result.stdout)
    assert String.starts_with?(trimmed, scratch_root <> "/kiln-verification-")
    refute trimmed == "/tmp"
  end

  test "environment_digest is sensitive to the per-command TMPDIR" do
    repository = repository!()
    command = tmpdir_echo_command(repository)

    assert {:ok, a} = CommandHost.run(command, tmpdir: "/tmp/kiln-tmpdir-digest-a")
    assert {:ok, b} = CommandHost.run(command, tmpdir: "/tmp/kiln-tmpdir-digest-b")
    assert {:ok, c} = CommandHost.run(command, tmpdir: "/tmp/kiln-tmpdir-digest-a")

    assert a.environment_digest != b.environment_digest
    assert a.environment_digest == c.environment_digest
  end

  defp tmpdir_echo_command(repository) do
    %Kiln.Verification.Registry.Command{
      id: "repo.tmpdir-echo",
      executable: "sh",
      argv: ["-c", ~s(echo "$TMPDIR")],
      cwd: repository,
      timeout_ms: 30_000,
      proves: ["patch-hygiene"],
      registration_digest: "sha256:" <> String.duplicate("0", 64)
    }
  end

  defp repository! do
    root = Path.join(System.tmp_dir!(), "kiln-command-host-#{System.unique_integer([:positive])}")
    repository = Path.join(root, "loadout")
    File.mkdir_p!(repository)
    File.write!(Path.join(repository, "README.md"), "# test\n")
    git!(repository, ["init", "-q", "-b", "main"])
    git!(repository, ["config", "user.email", "test@local"])
    git!(repository, ["config", "user.name", "Test"])
    git!(repository, ["add", "."])
    git!(repository, ["commit", "-q", "-m", "baseline"])
    on_exit(fn -> File.rm_rf(root) end)
    repository
  end

  defp git!(repository, args) do
    {output, 0} = System.cmd("git", args, cd: repository, stderr_to_stdout: true)
    output
  end
end
