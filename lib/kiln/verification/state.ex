defmodule Kiln.Verification.State do
  @moduledoc "Exact git change-state observation used before and after verification."

  @spec observe(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def observe(repository, base_commit, git \\ "git") do
    with {:ok, head} <- command(git, ["-C", repository, "rev-parse", "HEAD"]),
         {:ok, diff} <-
           command_raw(git, [
             "-C",
             repository,
             "diff",
             "--binary",
             base_commit,
             "--",
             ".",
             ":(exclude).loadout/**"
           ]),
         {:ok, untracked} <-
           command_raw(git, [
             "-C",
             repository,
             "ls-files",
             "--others",
             "--exclude-standard",
             "-z"
           ]),
         {:ok, digest} <- patch_digest(repository, diff, untracked) do
      {:ok, %{head_commit: String.trim(head), patch_digest: digest}}
    end
  end

  defp patch_digest(repository, diff, untracked) do
    paths =
      untracked
      |> :binary.split(<<0>>, [:global])
      |> Enum.reject(&(&1 == "" or &1 == ".loadout" or String.starts_with?(&1, ".loadout/")))
      |> Enum.sort()

    context = :crypto.hash_init(:sha256) |> :crypto.hash_update(diff)

    Enum.reduce_while(paths, {:ok, context}, fn relative, {:ok, acc} ->
      case File.read(Path.join(repository, relative)) do
        {:ok, bytes} ->
          next = :crypto.hash_update(acc, [<<0>>, "untracked", <<0>>, relative, <<0>>, bytes])
          {:cont, {:ok, next}}

        {:error, reason} ->
          {:halt, {:error, {:untracked_file_unreadable, relative, reason}}}
      end
    end)
    |> case do
      {:ok, final} ->
        {:ok, "sha256:" <> (:crypto.hash_final(final) |> Base.encode16(case: :lower))}

      {:error, _} = error ->
        error
    end
  end

  defp command(executable, argv) do
    case System.cmd(executable, argv, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, status} -> {:error, {:git_failed, status, output}}
    end
  rescue
    error -> {:error, {:git_unavailable, Exception.message(error)}}
  end

  defp command_raw(executable, argv), do: command(executable, argv)
end
