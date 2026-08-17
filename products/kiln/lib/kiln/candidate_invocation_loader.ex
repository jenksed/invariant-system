defmodule Kiln.CandidateInvocationLoader do
  @moduledoc """
  Read a Candidate Invocation request payload from disk.

  Accepts JSON inputs (`.json`) only. The CLI's `--request` flag accepts
  a path; this loader reads it and returns the parsed map that
  `Kiln.CandidateInvocation.new_request/1` accepts.

  The loader never executes code, never reaches into the Store, and
  performs no filesystem mutation. It is intentionally kept separate
  from `Kiln.CLI` so the P1-S01 slice test (`p1_s01_test.exs`) can
  authorise loader modules without granting the dispatcher the
  "read Repository source" capability.

  The bounded error envelope matches `Kiln.CLI.Result`: a
  `result_kind` of `:read_error` (file IO failure) or `:invalid_payload`
  (JSON decode failure or non-object root). The CLI dispatcher
  translates these into the consumer-visible Result; this loader is
  payload-only and does not import any CLI module.
  """

  @type loader_error :: %{
          required(:result_kind) => :read_error | :invalid_payload,
          required(:reason) => String.t(),
          required(:path) => Path.t(),
          required(:details) => map()
        }

  @doc """
  Load a Candidate Invocation request payload from `path`.

  Returns `{:ok, attrs}` where `attrs` is the map shape, or
  `{:error, loader_error}`.
  """
  @spec load(Path.t()) :: {:ok, map()} | {:error, loader_error()}
  def load(path) when is_binary(path) do
    case File.read(path) do
      {:ok, contents} ->
        parse(contents, path)

      {:error, reason} ->
        {:error,
         %{
           result_kind: :read_error,
           reason: "candidate invocation request file could not be read",
           path: path,
           details: %{reason: inspect(reason)}
         }}
    end
  end

  defp parse(contents, path) do
    case JSON.decode(contents) do
      {:ok, value} when is_map(value) ->
        {:ok, value}

      {:ok, _other} ->
        {:error,
         %{
           result_kind: :invalid_payload,
           reason: "candidate invocation request payload must be a JSON object at the top level",
           path: path,
           details: %{}
         }}

      {:error, reason} ->
        {:error,
         %{
           result_kind: :invalid_payload,
           reason: "candidate invocation request JSON could not be decoded",
           path: path,
           details: %{reason: inspect(reason)}
         }}
    end
  end
end
