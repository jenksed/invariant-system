defmodule Kiln.M0CommandLoader do
  @moduledoc """
  Bounded loader for the M0 (KILN-M0-02) CLI command inputs.

  The M8 CLI commands (`:worker_propose`, `:patch_decide`,
  `:patch_apply`, `:patch_recover`) accept user-supplied JSON
  artifact paths via flags. This loader is the canonical read site
  for those artifacts; the CLI dispatcher delegates every
  `File.read` call here so the P1-S01 "no P1-S01 runtime module reads
  Repository source content" architecture-policing slice test
  continues to hold.

  All paths passed in are operator-supplied via CLI flags, never
  derived from active repository traversal. The loader never
  performs repository ingestion. Every error is bounded and
  non-raising.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  @type load_result :: {:ok, map()} | {:error, %{reason: String.t(), path: String.t()}}

  @doc "Load a JSON artifact from `path`. Returns the decoded map or a bounded error."
  @spec load_json(Path.t() | nil, String.t()) :: load_result()
  def load_json(nil, field) when is_binary(field) do
    {:error, %{reason: "--#{field} is required", path: "<not provided>"}}
  end

  def load_json(path, field) when is_binary(path) and is_binary(field) do
    case File.read(path) do
      {:ok, contents} ->
        case JSON.decode(contents) do
          {:ok, doc} when is_map(doc) ->
            {:ok, doc}

          # M11 E2 B-repair: the `--operations` argument to
          # `mix kiln patch-apply` is a JSON array of bounded ops
          # (e.g. [{op, path, ...}, ...]). The previous loader
          # accepted only JSON objects, which forced every
          # caller of `--operations` to wrap the list in a
          # map (e.g. {"operations": [...]}). Accept JSON arrays
          # here so the canonical CLI can pass the bounded ops
          # list directly. The downstream PatchService.apply/3
          # iterates the value as a list either way.
          {:ok, doc} when is_list(doc) ->
            {:ok, doc}

          _ ->
            {:error, %{reason: "#{field} JSON must be an object or array", path: path}}
        end

      {:error, reason} ->
        {:error, %{reason: "cannot read --#{field}: #{inspect(reason)}", path: path}}
    end
  end

  def load_json(_, field),
    do: {:error, %{reason: "--#{field} is required", path: "<not provided>"}}

  @doc "Default placeholder for `--plan` when the operator does not supply one."
  @spec default_plan_ref() :: map()
  def default_plan_ref do
    %{"id" => "pln_default", "digest" => "sha256:" <> String.duplicate("0", 64)}
  end

  @doc """
  Resolve a Profile by `semantic_digest` from the M6 evidence on
  disk. This is the bounded reader for the M8 Worker; the dispatcher
  never opens Profile files itself.
  """
  @spec resolve_profile(String.t(), Path.t()) ::
          {:ok, map()} | {:error, %{reason: String.t()}}
  def resolve_profile(digest, profiles_root \\ default_profiles_root()) when is_binary(digest) do
    candidates = [
      Path.join(profiles_root, "implementer.json"),
      Path.join(profiles_root, "reviewer.json")
    ]

    Enum.find_value(
      candidates,
      {:error, %{reason: "profile not found by digest", path: "<profiles>"}},
      fn path ->
        case File.read(path) do
          {:ok, body} ->
            case JSON.decode(body) do
              {:ok, %{"semantic_digest" => ^digest} = profile} -> {:ok, profile}
              _ -> nil
            end

          _ ->
            nil
        end
      end
    )
  end

  defp default_profiles_root do
    # Existing canonical seam: when KILN_PROFILES_ROOT is set in the
    # environment, the resolver uses it as the profiles root. This
    # lets the M11 E2 scenario point at a fixture-staged profiles
    # dir without mutating the Arsenal source tree or adding a second
    # resolver. When the env var is unset, fall back to the
    # canonical Arsenal M0 profile location relative to CWD.
    case System.get_env("KILN_PROFILES_ROOT") do
      nil ->
        Path.expand(
          "../../../../products/arsenal/evaluation/profiles/m0",
          File.cwd!()
        )

      root when is_binary(root) and root != "" ->
        root

      _ ->
        Path.expand(
          "../../../../products/arsenal/evaluation/profiles/m0",
          File.cwd!()
        )
    end
  end
end
