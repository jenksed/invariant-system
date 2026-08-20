defmodule Kiln.Domain.SubjectIdentity do
  @moduledoc """
  M4 — canonical SubjectIdentity domain.

  A SubjectIdentity uniquely identifies one graph entity within
  the supported canonical projection domain. It carries:

    * `entity_type` — the canonical M3 envelope type (or one of
      the bounded aliases the projection recognises).
    * `canonical_id` — the envelope's `id` field.

  Two SubjectIdentity values are equal iff both fields are equal.
  Hashable via `digest/1` for use as a map key, set element, or
  edge endpoint identity.

  Use cases:
    * Work Map selection
    * Inspector subject
    * Proof subject
    * WHY subject
    * Async explanation request correlation
    * Focus preservation across re-renders
    * Navigation target
    * Stale-response validation

  Avoid string-prefix conventions as an implicit type system.
  SubjectIdentity is the only SubjectIdentity.

  Architecture: Kiln.M4 (M4-A, lane M4).
  """

  @type t :: %__MODULE__{
          entity_type: String.t(),
          canonical_id: String.t()
        }

  @enforce_keys [:entity_type, :canonical_id]
  defstruct [:entity_type, :canonical_id]

  @known_entity_types ~w(
    WorkerOutput
    PatchProposal
    VerificationResult
    Review
    HumanDecision
    PatchEvidence
    EngineeringObjective
  )

  @doc "Construct a SubjectIdentity from a canonical M3 envelope struct."
  @spec from_envelope(struct()) :: {:ok, t()} | {:error, :unknown_entity_type}
  def from_envelope(%{__struct__: mod, id: id}) do
    type = entity_type_for_module(mod)

    cond do
      type == nil -> {:error, :unknown_entity_type}
      true -> {:ok, %__MODULE__{entity_type: type, canonical_id: id}}
    end
  end

  @doc "Construct a SubjectIdentity directly from a known type + id."
  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def new(type, id) when is_binary(type) and is_binary(id) and byte_size(id) > 0 do
    cond do
      type in @known_entity_types -> {:ok, %__MODULE__{entity_type: type, canonical_id: id}}
      true -> {:error, {:unknown_entity_type, type}}
    end
  end

  @doc "Stable hash for use as map key / set element."
  @spec digest(t()) :: String.t()
  def digest(%__MODULE__{entity_type: type, canonical_id: id}) do
    "sha256:" <> Base.encode16(:crypto.hash(:sha256, type <> "/" <> id), case: :lower)
  end

  @doc "Three-valued knowledge enum."
  @type knowledge :: :present | :absent | :unknown

  @doc "Translate a missing canonical fact to three-valued knowledge."
  @spec knowledge(any()) :: knowledge()
  def knowledge(nil), do: :absent
  def knowledge(:__missing__), do: :unknown
  def knowledge(:__hydration_pending__), do: :unknown
  def knowledge(:__stale__), do: :unknown
  def knowledge(_other), do: :present

  @doc "True iff knowledge is :present."
  @spec present?(knowledge()) :: boolean()
  def present?(:present), do: true
  def present?(_), do: false

  @doc "True iff knowledge is :unknown."
  @spec unknown?(knowledge()) :: boolean()
  def unknown?(:unknown), do: true
  def unknown?(_), do: false

  # --- private ---

  defp entity_type_for_module(Kiln.M0WorkerOutput), do: "WorkerOutput"
  defp entity_type_for_module(Kiln.M0PatchProposal), do: "PatchProposal"
  defp entity_type_for_module(Kiln.M0VerificationResult), do: "VerificationResult"
  defp entity_type_for_module(Kiln.M0Review), do: "Review"
  defp entity_type_for_module(Kiln.M0HumanDecision), do: "HumanDecision"
  defp entity_type_for_module(Kiln.M0PatchEvidence), do: "PatchEvidence"
  defp entity_type_for_module(_), do: nil
end
