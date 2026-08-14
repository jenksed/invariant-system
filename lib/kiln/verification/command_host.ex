defmodule Kiln.Verification.CommandHost do
  @moduledoc """
  No-shell host for a command already accepted by `Kiln.Verification.Registry`.

  The private native helper uses `posix_spawn`, a fresh process group, bounded
  timeout escalation, exact argv, a fixed cwd, a minimal environment, and
  separate stdout/stderr files. This module never accepts raw shell text.
  """

  alias Kiln.Verification.Registry.Command

  @spec run(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(%Command{} = command, opts \\ []) do
    with {:ok, executable} <- resolve_executable(command.executable, command.cwd),
         {:ok, helper} <- ensure_helper(opts),
         {:ok, directory} <- make_temp_dir(opts) do
      execute(helper, executable, command, directory, opts)
    end
  end

  defp execute(helper, executable, command, directory, opts) do
    stdout_path = Path.join(directory, "stdout")
    stderr_path = Path.join(directory, "stderr")
    result_path = Path.join(directory, "result.json")
    path_value = Keyword.get(opts, :path, System.get_env("PATH") || "/usr/bin:/bin")
    home_value = Keyword.get(opts, :home, System.get_env("HOME") || System.tmp_dir!())
    tmpdir_value = Keyword.get(opts, :tmpdir, directory)

    args = [
      "--cwd",
      command.cwd,
      "--timeout-ms",
      Integer.to_string(command.timeout_ms),
      "--stdout",
      stdout_path,
      "--stderr",
      stderr_path,
      "--result",
      result_path,
      "--path",
      path_value,
      "--home",
      home_value,
      "--tmpdir",
      tmpdir_value,
      "--",
      executable
      | command.argv
    ]

    try do
      case System.cmd(helper, args, stderr_to_stdout: true) do
        {_output, 0} ->
          with {:ok, result_bytes} <- File.read(result_path),
               {:ok, result} when is_map(result) <- JSON.decode(result_bytes),
               {:ok, stdout} <- File.read(stdout_path),
               {:ok, stderr} <- File.read(stderr_path) do
            {:ok,
             %{
               command_id: command.id,
               executable: executable,
               argv: command.argv,
               cwd: command.cwd,
               timeout_ms: command.timeout_ms,
               environment_policy: "minimal-toolchain-path",
               environment_digest:
                 digest(
                   path_value <>
                     "\n" <> home_value <>
                     "\n" <> tmpdir_value <> "\nCI=1\nMIX_ENV=test"
                 ),
               network_policy: "not-required",
               registration_digest: command.registration_digest,
               exit_code: result["exit_code"],
               signal: result["signal"],
               timed_out: result["timed_out"],
               duration_ms: result["duration_ms"],
               stdout: stdout,
               stderr: stderr,
               result: classify(result)
             }}
          else
            _ -> {:error, {:malformed_command_host_result, command.id}}
          end

        {output, status} ->
          {:error, {:command_host_failed, status, output}}
      end
    after
      File.rm_rf(directory)
    end
  end

  defp classify(%{"timed_out" => true}), do: :blocked
  defp classify(%{"exit_code" => 0, "signal" => 0}), do: :pass
  defp classify(_), do: :fail

  defp resolve_executable(name, cwd) do
    resolved =
      if String.contains?(name, "/"),
        do: Path.expand(name, cwd),
        else: System.find_executable(name)

    cond do
      not is_binary(resolved) ->
        {:error, {:executable_unavailable, name}}

      not File.regular?(resolved) ->
        {:error, {:executable_unavailable, name}}

      String.contains?(name, "/") and not inside?(resolved, cwd) ->
        {:error, {:executable_outside_repository, name}}

      true ->
        {:ok, resolved}
    end
  end

  defp inside?(path, root) do
    relative = Path.relative_to(path, Path.expand(root))
    relative != ".." and not String.starts_with?(relative, "../")
  end

  defp ensure_helper(opts) do
    source = Path.expand("../../../c_src/kiln_command_host.c", __DIR__)
    {:ok, source_bytes} = File.read(source)

    destination =
      Path.join(
        Keyword.get(opts, :helper_dir, System.tmp_dir!()),
        "kiln-command-host-" <> String.slice(digest(source_bytes), 7, 16)
      )

    if File.regular?(destination) do
      {:ok, destination}
    else
      compiler = Keyword.get(opts, :cc, System.find_executable("cc"))

      if is_nil(compiler) do
        {:error, :c_compiler_unavailable}
      else
        temporary = destination <> ".#{System.unique_integer([:positive])}"

        case System.cmd(
               compiler,
               ["-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", "-o", temporary, source],
               stderr_to_stdout: true
             ) do
          {_output, 0} ->
            File.chmod!(temporary, 0o700)

            case File.rename(temporary, destination) do
              :ok ->
                {:ok, destination}

              {:error, :eexist} ->
                File.rm(temporary)
                {:ok, destination}

              {:error, reason} ->
                {:error, {:helper_publish_failed, reason}}
            end

          {output, status} ->
            {:error, {:helper_compile_failed, status, output}}
        end
      end
    end
  end

  defp make_temp_dir(opts) do
    root = Keyword.get(opts, :temp_dir, System.tmp_dir!())
    directory = Path.join(root, "kiln-verification-#{System.unique_integer([:positive])}")

    case File.mkdir(directory) do
      :ok -> {:ok, directory}
      {:error, reason} -> {:error, {:temp_dir_failed, reason}}
    end
  end

  defp digest(bytes),
    do: "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
end
