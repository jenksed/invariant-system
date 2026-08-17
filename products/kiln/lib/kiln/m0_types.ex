defmodule Kiln.M0WorkerOutput do
  @moduledoc """
  Bounded Worker Output envelope emitted by `Kiln.Worker.propose/5`.
  Carries the parsed candidate digest plus a reference to the raw
  completion artifact; the Patch Proposal builder consumes both.

  Module name is `Kiln.M0WorkerOutput` (sibling of `Kiln.Worker`, not
  nested) to keep the compile graph flat — the bounded envelope is
  a distinct artifact kind.
  """

  defstruct [
    :id,
    :semantic_digest,
    :attempt_ref,
    :assignment_ref,
    :profile_ref,
    :output_kind,
    :raw_completion_ref,
    :parsed_candidate_digest,
    :completion_bytes,
    :base_commit,
    :base_state_digest,
    :adapter_implementation_digest
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          attempt_ref: map(),
          assignment_ref: map(),
          profile_ref: map(),
          output_kind: String.t(),
          raw_completion_ref: map(),
          parsed_candidate_digest: String.t(),
          completion_bytes: binary(),
          base_commit: String.t() | nil,
          base_state_digest: String.t(),
          adapter_implementation_digest: String.t()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = output) do
    Map.from_struct(output)
    |> Map.update!(:completion_bytes, &Base.encode16(&1, case: :lower))
  end
end

defmodule Kiln.M0PatchProposal do
  @moduledoc """
  Canonical Patch Proposal envelope emitted by `Kiln.PatchProposal.build/4`.
  The Patch Service consumes this envelope + the corresponding Worker
  Output to apply the approved bytes only after explicit ACCEPT.
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :attempt_ref,
    :repository,
    :base_commit,
    :base_state_digest,
    :operations,
    :patch_digest,
    :metadata
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          attempt_ref: map(),
          repository: String.t(),
          base_commit: String.t() | nil,
          base_state_digest: String.t(),
          operations: [map()],
          patch_digest: String.t(),
          metadata: map()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = proposal) do
    Map.from_struct(proposal)
  end
end

defmodule Kiln.M0PatchDecision do
  @moduledoc "Canonical Patch Decision envelope (m0-v1)."
  defstruct [
    :id,
    :semantic_digest,
    :patch_ref,
    :base_state_digest,
    :decision,
    :proposal
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          patch_ref: map(),
          base_state_digest: String.t(),
          decision: String.t(),
          proposal: Kiln.M0PatchProposal.t()
        }
end

defmodule Kiln.M0PatchEvidence do
  @moduledoc "Canonical Patch Application Evidence envelope (m0-v1)."
  defstruct [
    :id,
    :semantic_digest,
    :patch_ref,
    :decision_ref,
    :pre_state_digest,
    :post_state_digest,
    :effect
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          patch_ref: map(),
          decision_ref: map(),
          pre_state_digest: String.t(),
          post_state_digest: String.t(),
          effect: String.t()
        }
end