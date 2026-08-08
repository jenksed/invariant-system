defmodule Kiln.VerificationManifest do
  @moduledoc """
  Construction and validation of a slice verification manifest.

  A slice verification manifest is bounded **implementation Evidence**: it
  records which exact Repository state a slice's aggregate gate, demo,
  conformance checks, and owner-machine checks were proved against, and it
  binds that record to a self-integrity digest so a manifest cannot be
  reused to describe a different commit.

  ## What this is not

  A manifest is not a product Receipt. It carries no authority. Per
  `docs/SLICE-ACCEPTANCE-GATES.md` (gate rules 8, 9, and 13) it cannot:

    * satisfy a Task;
    * complete a Run;
    * record user product acceptance;
    * act as a product Receipt;
    * authorize a later slice;
    * make a failed, blocked, stale, or missing gate pass.

  Those refusals are encoded explicitly in the `"not_authority"` section so a
  reader of the serialized document cannot mistake the manifest's scope, and
  `validate/1` rejects a document whose refusals were edited.

  ## State binding

  `build/1` requires the exact facts that identify what was proved:
  Repository commit and clean/dirty fingerprint, toolchain, store format and
  migration identity, the aggregate gate result, the demo result, the
  conformance results, and the owner-machine result. `overall/1` is derived,
  never supplied: a manifest reports `"pass"` only when every required
  component passed and the working tree was clean. Any `fail`, `blocked`, or
  unknown component, or a dirty tree, downgrades the manifest.

  ## Self-integrity

  The digest covers the canonical encoding of every field except the digest
  itself, bound to `#{inspect(__MODULE__)}`'s schema identifier. `validate/1`
  recomputes it. A manifest whose commit, gate result, or refusals were
  altered after generation fails validation, so a previously passing artifact
  cannot silently prove a later commit.
  """

  alias Kiln.Store.Canonical

  @schema "kiln.slice_verification_manifest/v1"

  @required_components [:gate, :demo, :conformance, :owner_machine]

  @typedoc "A component outcome. Only `:pass` contributes to an overall pass."
  @type outcome :: :pass | :fail | :blocked | :unknown | :not_run

  @type t :: map()

  @doc "The manifest schema identifier."
  @spec schema() :: String.t()
  def schema, do: @schema

  @doc """
  Build a slice verification manifest from exact observed facts.

  Required keys: `:manifest_id`, `:slice`, `:repository`, `:toolchain`,
  `:store`, `:gate`, `:demo`, `:conformance`, `:owner_machine`, `:created_at`.
  Optional: `:tickets`, `:warnings`, `:exclusions`, `:unknowns`.

  Returns `{:ok, manifest}` or `{:error, reason}`. The manifest is a plain
  string-keyed map suitable for canonical JSON encoding.
  """
  @spec build(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def build(attrs) when is_list(attrs), do: attrs |> Map.new() |> build()

  def build(attrs) when is_map(attrs) do
    with :ok <- require_keys(attrs),
         {:ok, repository} <- normalize_repository(attrs[:repository]),
         {:ok, components} <- normalize_components(attrs) do
      body = %{
        "schema" => @schema,
        "manifest_id" => to_string(attrs[:manifest_id]),
        "slice" => to_string(attrs[:slice]),
        "kind" => "implementation_evidence",
        "created_at" => to_string(attrs[:created_at]),
        "repository" => repository,
        "toolchain" => stringify(attrs[:toolchain]),
        "store" => stringify(attrs[:store]),
        "tickets" => Enum.map(attrs[:tickets] || [], &stringify/1),
        "components" => components,
        "warnings" => Enum.map(attrs[:warnings] || [], &to_string/1),
        "exclusions" => Enum.map(attrs[:exclusions] || [], &to_string/1),
        "unknowns" => Enum.map(attrs[:unknowns] || [], &to_string/1),
        "not_authority" => not_authority(),
        "overall" => overall(components, repository)
      }

      {:ok, Map.put(body, "digest", "sha256:" <> Canonical.digest(@schema, body))}
    end
  end

  @doc """
  Validate a manifest document.

  Checks the schema identifier, the presence of every required component, the
  exact non-authority refusals, that `overall` still equals the value derived
  from the recorded components and Repository state, and that the self-digest
  recomputes. Returns `:ok` or `{:error, reason}`.
  """
  @spec validate(t()) :: :ok | {:error, term()}
  def validate(manifest) when is_map(manifest) do
    with :ok <- validate_schema(manifest),
         :ok <- validate_components_present(manifest),
         :ok <- validate_not_authority(manifest),
         :ok <- validate_overall(manifest) do
      validate_digest(manifest)
    end
  end

  def validate(_other), do: {:error, :not_a_map}

  @doc """
  Derive the overall result from component outcomes and Repository state.

  Returns `"pass"` only when every required component is `pass` and the
  working tree was clean. A dirty tree yields `"blocked"` because the proved
  state is not the recorded commit. Any failing component yields `"fail"`;
  otherwise `"blocked"`.
  """
  @spec overall(map(), map()) :: String.t()
  def overall(components, repository) when is_map(components) and is_map(repository) do
    outcomes = Enum.map(@required_components, &get_outcome(components, &1))

    cond do
      Enum.any?(outcomes, &(&1 == "fail")) -> "fail"
      repository["dirty"] == true -> "blocked"
      Enum.all?(outcomes, &(&1 == "pass")) -> "pass"
      true -> "blocked"
    end
  end

  # -- normalization --

  defp require_keys(attrs) do
    required = [
      :manifest_id,
      :slice,
      :repository,
      :toolchain,
      :store,
      :gate,
      :demo,
      :conformance,
      :owner_machine,
      :created_at
    ]

    case Enum.reject(required, &Map.has_key?(attrs, &1)) do
      [] -> :ok
      missing -> {:error, {:missing_keys, missing}}
    end
  end

  # The commit is required and the dirty flag is required to be an explicit
  # boolean: an absent dirty flag must not be read as "clean". A dirty tree
  # additionally requires a fingerprint so the proved state is identifiable.
  defp normalize_repository(repository) when is_map(repository) do
    commit = repository[:commit] || repository["commit"]
    dirty = repository[:dirty]
    dirty = if is_nil(dirty), do: repository["dirty"], else: dirty

    cond do
      not (is_binary(commit) and commit =~ ~r/^[0-9a-f]{40}$/) ->
        {:error, {:invalid_commit, commit}}

      not is_boolean(dirty) ->
        {:error, {:invalid_dirty_flag, dirty}}

      true ->
        {:ok, repository |> stringify() |> Map.put("commit", commit) |> Map.put("dirty", dirty)}
    end
  end

  defp normalize_repository(other), do: {:error, {:invalid_repository, other}}

  defp normalize_components(attrs) do
    Enum.reduce_while(@required_components, {:ok, %{}}, fn key, {:ok, acc} ->
      case normalize_component(attrs[key]) do
        {:ok, component} -> {:cont, {:ok, Map.put(acc, to_string(key), component)}}
        {:error, reason} -> {:halt, {:error, {key, reason}}}
      end
    end)
  end

  defp normalize_component(component) when is_map(component) do
    outcome = component[:outcome] || component["outcome"]

    if to_string(outcome) in ~w(pass fail blocked unknown not_run) do
      {:ok, component |> stringify() |> Map.put("outcome", to_string(outcome))}
    else
      {:error, {:invalid_outcome, outcome}}
    end
  end

  defp normalize_component(other), do: {:error, {:invalid_component, other}}

  defp get_outcome(components, key) do
    case components[to_string(key)] do
      %{"outcome" => outcome} -> outcome
      _ -> "unknown"
    end
  end

  # The refusals are data, not prose, so `validate/1` can detect an edited
  # document that tries to claim authority the manifest does not have.
  defp not_authority do
    %{
      "satisfies_task" => false,
      "completes_run" => false,
      "records_user_product_acceptance" => false,
      "is_product_receipt" => false,
      "authorizes_next_slice" => false,
      "can_make_a_failed_gate_pass" => false,
      "statement" =>
        "This manifest is bounded implementation Evidence for one slice. It carries no authority: it does not satisfy a Task, complete a Run, record product acceptance, act as a product Receipt, or authorize any later slice."
    }
  end

  # -- validation --

  defp validate_schema(%{"schema" => @schema}), do: :ok
  defp validate_schema(manifest), do: {:error, {:invalid_schema, manifest["schema"]}}

  defp validate_components_present(manifest) do
    components = manifest["components"] || %{}

    case Enum.reject(@required_components, &Map.has_key?(components, to_string(&1))) do
      [] -> :ok
      missing -> {:error, {:missing_components, missing}}
    end
  end

  defp validate_not_authority(%{"not_authority" => actual}) do
    expected = not_authority()

    if actual == expected do
      :ok
    else
      {:error, :not_authority_altered}
    end
  end

  defp validate_not_authority(_manifest), do: {:error, :missing_not_authority}

  defp validate_overall(manifest) do
    expected = overall(manifest["components"] || %{}, manifest["repository"] || %{})

    if manifest["overall"] == expected do
      :ok
    else
      {:error, {:overall_mismatch, expected: expected, recorded: manifest["overall"]}}
    end
  end

  defp validate_digest(manifest) do
    {recorded, body} = Map.pop(manifest, "digest")
    expected = "sha256:" <> Canonical.digest(@schema, body)

    if recorded == expected do
      :ok
    else
      {:error, {:digest_mismatch, expected: expected, recorded: recorded}}
    end
  end

  # -- helpers --

  defp stringify(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify(value)} end)
  end

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)

  defp stringify(value) when is_atom(value) and not is_boolean(value) and not is_nil(value),
    do: to_string(value)

  defp stringify(value), do: value
end
