defmodule Kiln.CandidateInvocation do
  @moduledoc """
  Canonical M0 Candidate Invocation contract.

  Mirrors `engineering-system/candidate-invocation/m0-v1` exactly: closed-shape
  typed struct, validation against the ratified schema fields, and canonical
  encoding + `semantic_digest` per P02-D013 (using `Kiln.Store.Canonical`
  rules: sorted keys, compact UTF-8).

  The schema identity (`engineering-system/candidate-invocation/m0-v1`) is
  folded into every digest so two payloads that encode identically under
  different schemas still receive distinct digests.

  Adapter identities (production and qualification) are identical at this
  contract surface; mode changes authority and limits only (P02-D020).
  """

  @schema_id "engineering-system/candidate-invocation/m0-v1"

  @failure_classification "M0_CANONICAL_FAILURE_TAXONOMY_V1"

  @allowed_modes ~w(QUALIFICATION PRODUCTION)
  @allowed_output_contracts ~w(IMPLEMENTER_PATCH_PROPOSAL REVIEW_VERDICT)
  @min_timeout_ms 1_000
  @max_timeout_ms 1_800_000

  @type artifact_ref :: %{required(:id) => String.t(), required(:digest) => String.t()}
  @type mode :: :QUALIFICATION | :PRODUCTION
  @type output_contract :: :IMPLEMENTER_PATCH_PROPOSAL | :REVIEW_VERDICT
  @type failure_class ::
          :E_RUNTIME_UNAVAILABLE
          | :E_PROVIDER_DENIED
          | :E_TIMEOUT
          | :E_TERMINAL_RESULT
          | :E_CONNECTION_LOST
          | :E_UNKNOWN
          | :E_MALFORMED_OUTPUT
          | :E_POLICY_REJECTION

  @type t :: %__MODULE__{
          schema: String.t(),
          invocation_id: String.t(),
          mode: mode(),
          profile_ref: artifact_ref(),
          context_manifest_ref: artifact_ref(),
          tool_policy_ref: artifact_ref(),
          timeout_ms: pos_integer(),
          output_contract: output_contract(),
          failure_classification: String.t(),
          engineering_objective: String.t() | nil,
          semantic_digest: String.t()
        }

  @enforce_keys [
    :schema,
    :invocation_id,
    :mode,
    :profile_ref,
    :context_manifest_ref,
    :tool_policy_ref,
    :timeout_ms,
    :output_contract,
    :failure_classification,
    :semantic_digest
  ]
  defstruct @enforce_keys ++ [engineering_objective: nil]

  @doc "The canonical schema identity string."
  @spec schema_id() :: String.t()
  def schema_id, do: @schema_id

  @doc "The frozen failure classification constant for this contract."
  @spec failure_classification() :: String.t()
  def failure_classification, do: @failure_classification

  @doc "Construct a request struct from validated inputs. Does not compute the digest."
  @spec new_request(map()) :: {:ok, t()} | {:error, term()}
  def new_request(attrs) when is_map(attrs) do
    attrs = normalize_keys(attrs)

    with {:ok, invocation_id} <- require_string(attrs, :invocation_id),
         {:ok, mode} <- require_enum(attrs, :mode, @allowed_modes),
         {:ok, profile_ref} <- require_artifact_ref(attrs, :profile_ref),
         {:ok, context_manifest_ref} <- require_artifact_ref(attrs, :context_manifest_ref),
         {:ok, tool_policy_ref} <- require_artifact_ref(attrs, :tool_policy_ref),
         {:ok, timeout_ms} <- require_timeout(attrs),
         {:ok, output_contract} <-
           require_enum(attrs, :output_contract, @allowed_output_contracts),
         {:ok, engineering_objective} <- optional_objective(attrs) do
      identity_payload = %{
        invocation_id: invocation_id,
        mode: Atom.to_string(mode),
        profile_ref: profile_ref,
        context_manifest_ref: context_manifest_ref,
        tool_policy_ref: tool_policy_ref,
        timeout_ms: timeout_ms,
        output_contract: Atom.to_string(output_contract),
        failure_classification: @failure_classification
      }

      {:ok,
       %__MODULE__{
         schema: @schema_id,
         invocation_id: invocation_id,
         mode: mode,
         profile_ref: profile_ref,
         context_manifest_ref: context_manifest_ref,
         tool_policy_ref: tool_policy_ref,
         timeout_ms: timeout_ms,
         output_contract: output_contract,
         failure_classification: @failure_classification,
         engineering_objective: engineering_objective,
         semantic_digest: canonical_digest(identity_payload)
       }}
    end
  end

  @doc "Recompute the canonical semantic digest for an existing struct."
  @spec recompute_digest(t()) :: String.t()
  def recompute_digest(%__MODULE__{} = struct) do
    identity_payload = %{
      invocation_id: struct.invocation_id,
      mode: Atom.to_string(struct.mode),
      profile_ref: struct.profile_ref,
      context_manifest_ref: struct.context_manifest_ref,
      tool_policy_ref: struct.tool_policy_ref,
      timeout_ms: struct.timeout_ms,
      output_contract: Atom.to_string(struct.output_contract),
      failure_classification: struct.failure_classification
    }

    canonical_digest(identity_payload, struct.schema)
  end

  @doc "Build a terminal result from a failure class. Result carries no adapter-restatement."
  @spec terminal_result(failure_class()) :: %{
          required(:status) => failure_class(),
          required(:failure_classification) => String.t()
        }
  def terminal_result(failure_class) do
    %{status: failure_class, failure_classification: @failure_classification}
  end

  # --- private helpers ---

  defp canonical_digest(identity_payload, schema \\ @schema_id) do
    "sha256:" <> Kiln.Store.Canonical.digest(schema, identity_payload)
  end

  defp normalize_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {key, value}
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
    end)
  end

  defp require_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      nil ->
        {:error, {:missing_field, key}}

      other ->
        {:error, {:invalid_field, key, other}}
    end
  end

  defp require_enum(map, key, allowed) do
    case Map.get(map, key) do
      nil ->
        {:error, {:missing_field, key}}

      value when is_binary(value) ->
        if value in allowed do
          to_atom_safe(value)
        else
          {:error, {:invalid_field, key, value}}
        end

      other ->
        {:error, {:invalid_field, key, other}}
    end
  end

  # `String.to_existing_atom/1` rejects unallocated atoms; the M0 closed
  # enums (mode: QUALIFICATION|PRODUCTION, output_contract:
  # IMPLEMENTER_PATCH_PROPOSAL|REVIEW_VERDICT) are ratified by the
  # schema, so we map them explicitly here instead of falling through to
  # a generic atom lookup. This keeps the validation total without leaking
  # new atoms into the VM, and lets the dispatch convert the bounded
  # 3-tuple error into a structured Result.
  defp to_atom_safe("PRODUCTION"), do: {:ok, :PRODUCTION}
  defp to_atom_safe("QUALIFICATION"), do: {:ok, :QUALIFICATION}
  defp to_atom_safe("IMPLEMENTER_PATCH_PROPOSAL"), do: {:ok, :IMPLEMENTER_PATCH_PROPOSAL}
  defp to_atom_safe("REVIEW_VERDICT"), do: {:ok, :REVIEW_VERDICT}

  defp to_atom_safe(value) when is_binary(value) do
    {:error, {:invalid_field, :mode_atom, value}}
  end

  defp require_artifact_ref(map, key) do
    case Map.get(map, key) do
      %{"id" => id, "digest" => digest} when is_binary(id) and is_binary(digest) ->
        {:ok, %{id: id, digest: digest}}

      %{id: id, digest: digest} when is_binary(id) and is_binary(digest) ->
        {:ok, %{id: id, digest: digest}}

      nil ->
        {:error, {:missing_field, key}}

      other ->
        {:error, {:invalid_field, key, other}}
    end
  end

  # Optional field. Validates type but allows absence. The field
  # carries the bounded task statement for real-provider dispatches.
  # Schema: minLength=1 when present.
  defp optional_objective(map) do
    case Map.get(map, :engineering_objective) do
      nil ->
        {:ok, nil}

      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      other ->
        {:error, {:invalid_field, :engineering_objective, other}}
    end
  end

  defp require_timeout(map) do
    case Map.get(map, :timeout_ms) do
      value when is_integer(value) and value >= @min_timeout_ms and value <= @max_timeout_ms ->
        {:ok, value}

      nil ->
        {:error, {:missing_field, :timeout_ms}}

      other ->
        {:error, {:invalid_field, :timeout_ms, other}}
    end
  end
end
