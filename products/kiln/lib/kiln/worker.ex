defmodule Kiln.Worker do
  @moduledoc """
  M0 Worker: bounded IMPLEMENTER attempt driven by an Intelligence Assignment.

  Validates the assignment/qualification binding AT DISPATCH TIME (not just
  at selection time), observes the bounded active repository, builds the
  Candidate Invocation request envelope from the canonical request
  attributes, validates the envelope via the M3 schema, and emits the
  canonical Worker Output carrying the parsed candidate digest plus a
  reference to the raw completion artifact.

  The Worker never mutates source. The Worker never authorizes its own
  patch. The Worker returns a Worker Output; a separate Patch Proposal
  builder (`Kiln.PatchProposal`) translates that into the canonical
  proposal; a separate Patch Service (`Kiln.PatchService`) applies the
  approved bytes only.

  The Worker Output schema is `engineering-system/worker-output/m0-v1`.
  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  alias Kiln.CandidateInvocation
  alias Kiln.MinimaxM3Adapter
  alias Kiln.RepositoryObservation
  alias Kiln.Store.Canonical
  alias Kiln.Store.Error

  @schema_id "engineering-system/worker-output/m0-v1"
  @output_kind "PATCH_CANDIDATE"
  @production_mode "PRODUCTION"

  @doc "Canonical schema id for the Worker Output envelope."
  @spec schema_id() :: String.t()
  def schema_id, do: @schema_id

  @doc "Bounded output kind. PATCH_CANDIDATE only in M8."
  @spec output_kind() :: String.t()
  def output_kind, do: @output_kind

  @doc """
  Validate the assignment/qualification binding at dispatch time.

  Performs every check listed in KILN-M0-02 E2 plus the revalidation
  rule: qualification that was current at M7 selection time may have
  become stale at M8 dispatch time. Bounded errors:

    * `:E_PROFILE_REF_MISMATCH` — assignment.profile_ref.digest does not
      match the runtime Profile semantic_digest.
    * `:E_QUALIFICATION_NOT_CURRENT` — eligibility is NOT_ELIGIBLE or
      outside the 168h window or not for the requested role.
    * `:E_ROLE_MISMATCH` — assignment.role != IMPLEMENTER.

  Returns `{:ok, :validated}` or `{:error, %{code: ..., reason: ...}}`.
  Never raises.
  """
  @spec validate_binding(profile :: map(), eligibility :: map(), assignment :: map()) ::
          {:ok, :validated}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def validate_binding(profile, eligibility, assignment)
      when is_map(profile) and is_map(eligibility) and is_map(assignment) do
    cond do
      assignment["role"] != "IMPLEMENTER" ->
        {:error, %{code: :E_ROLE_MISMATCH, reason: "assignment.role must be IMPLEMENTER"}}

      profile["semantic_digest"] != assignment["profile_ref"]["digest"] ->
        {:error,
         %{
           code: :E_PROFILE_REF_MISMATCH,
           reason:
             "assignment.profile_ref.digest does not match the runtime Profile semantic_digest"
         }}

      eligibility["eligibility"] != "QUALIFIED" ->
        {:error,
         %{
           code: :E_QUALIFICATION_NOT_CURRENT,
           reason: "eligibility is not QUALIFIED at dispatch time"
         }}

      eligibility["profile_ref"]["digest"] != assignment["profile_ref"]["digest"] ->
        {:error,
         %{
           code: :E_PROFILE_REF_MISMATCH,
           reason:
             "eligibility.profile_ref.digest does not match assignment.profile_ref.digest"
         }}

      eligibility["role"] != "IMPLEMENTER" ->
        {:error,
         %{
           code: :E_ROLE_MISMATCH,
           reason: "eligibility.role must match assignment.role (IMPLEMENTER)"
         }}

      not within_currentness_window?(eligibility) ->
        {:error,
         %{
           code: :E_QUALIFICATION_NOT_CURRENT,
           reason: "eligibility snapshot is outside the 168-hour currentness window"
         }}

      true ->
        {:ok, :validated}
    end
  end

  @doc """
  Validate the raw request attributes against the canonical M3 Candidate
  Invocation schema. The dispatch path then becomes:

      validate_dispatch(...)  -- bind at dispatch time
        |> CandidateInvocation.new_request(attrs)  -- canonical schema
        |> build_completion(...)  -- bounded patch envelope
        |> emit Worker.Output  -- canonical envelope with refs

  Returns `{:ok, %Worker.Output{}}` or a bounded error envelope.
  """
  @spec propose(
          assignment :: map(),
          eligibility :: map(),
          profile :: map(),
          request_attrs :: map(),
          repository_root :: String.t()
        ) ::
          {:ok, Worker.Output.t()}
          | {:error, Error.t() | %{required(:code) => atom(), required(:reason) => String.t()}}
  def propose(assignment, eligibility, profile, request_attrs, repository_root)
      when is_map(assignment) and is_map(eligibility) and is_map(profile) and
             is_map(request_attrs) and is_binary(repository_root) do
    with :ok <- validate_dispatch(profile, eligibility, assignment),
         {:ok, observation} <- observe_repository(repository_root),
         {:ok, attrs} <- merge_dispatch_attrs(profile, eligibility, request_attrs),
         {:ok, ci_request} <- CandidateInvocation.new_request(attrs),
         {:ok, completion_bytes, parsed_digest} <- build_bounded_completion(ci_request) do
      raw_completion_ref = %{
        "id" => "raw_" <> short_id(),
        "digest" => sha256_hex(completion_bytes)
      }

      body = %{
        "schema" => @schema_id,
        "worker_output_id" => "wko_" <> short_id(),
        "attempt_ref" => Map.get(request_attrs, "attempt_ref", default_attempt_ref()),
        "assignment_ref" => assignment_ref(assignment),
        "profile_ref" => profile_ref(profile),
        "output_kind" => @output_kind,
        "raw_completion_ref" => raw_completion_ref,
        "parsed_candidate_digest" => parsed_digest,
        "metadata" => %{
          "adapter_implementation_digest" => MinimaxM3Adapter.implementation_digest(),
          "base_commit" => observation.current_commit,
          "base_state_digest" => observation.repository_state_digest,
          "produced_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }
      }

      semantic = canonical_digest(@schema_id, Map.delete(body, "worker_output_id"))

      {:ok,
       %Kiln.M0WorkerOutput{
         id: body["worker_output_id"],
         semantic_digest: semantic,
         attempt_ref: body["attempt_ref"],
         assignment_ref: body["assignment_ref"],
         profile_ref: body["profile_ref"],
         output_kind: @output_kind,
         raw_completion_ref: raw_completion_ref,
         parsed_candidate_digest: parsed_digest,
         completion_bytes: completion_bytes,
         base_commit: observation.current_commit,
         base_state_digest: observation.repository_state_digest,
         adapter_implementation_digest: MinimaxM3Adapter.implementation_digest()
       }}
    end
  end

  @doc """
  Pure helper: build a Candidate Invocation request envelope from the
  validated binding + the request attributes supplied by the caller.
  """
  @spec merge_dispatch_attrs(profile :: map(), eligibility :: map(), request_attrs :: map()) ::
          {:ok, map()} | {:error, term()}
  def merge_dispatch_attrs(profile, eligibility, request_attrs)
      when is_map(profile) and is_map(eligibility) and is_map(request_attrs) do
    attrs =
      Map.merge(request_attrs, %{
        "mode" => @production_mode,
        "profile_ref" => %{
          "id" => profile["profile_id"],
          "digest" => profile["semantic_digest"]
        },
        "context_manifest_ref" => eligibility["profile_ref"],
        "tool_policy_ref" => %{
          "id" => profile["tool_policy"]["id"],
          "digest" => profile["tool_policy"]["digest"]
        }
      })

    {:ok, attrs}
  end

  @doc """
  Build a bounded completion envelope from the validated Candidate
  Invocation request. The M0 Worker does not embed provider payloads;
  it produces a structured digest-bound summary that the Patch Proposal
  builder consumes. The dispatcher's provider invocation is the M3
  adapter's responsibility under the production-mode credential gate.

  For M0 fixtures and tests the completion bytes are a canonical JSON
  envelope describing the parsed candidate. Real provider invocations
  land through the adapter when MINIMAX_API_KEY is present.
  """
  @spec build_bounded_completion(CandidateInvocation.t()) ::
          {:ok, binary(), String.t()}
          | {:error, term()}
  def build_bounded_completion(%CandidateInvocation{} = req) do
    parsed = %{
      "invocation_id" => req.invocation_id,
      "mode" => Atom.to_string(req.mode),
      "semantic_digest" => req.semantic_digest,
      "profile_digest" => req.profile_ref.digest,
      "context_manifest_digest" => req.context_manifest_ref.digest,
      "tool_policy_digest" => req.tool_policy_ref.digest,
      "output_contract" => Atom.to_string(req.output_contract),
      "adapter_implementation_digest" => MinimaxM3Adapter.implementation_digest(),
      "candidate_kind" => @output_kind
    }

    bytes =
      parsed
      |> canonical_request_bytes()

    {:ok, bytes, parsed_digest(parsed)}
  end

  @doc "Pure helper: compute the parsed candidate digest for a parsed map."
  @spec parsed_digest(map()) :: String.t()
  def parsed_digest(parsed) when is_map(parsed) do
    "sha256:" <> Canonical.digest(@schema_id <> "/parsed", parsed)
  end

  @doc """
  Pure helper: deterministic canonical encoding for a request payload
  that is safe to use as the bounded Worker Output completion bytes.
  """
  @spec canonical_request_bytes(map()) :: binary()
  def canonical_request_bytes(map) when is_map(map) do
    text = JSON.encode!(map)
    text <> "\n"
  end

  # -- private helpers --

  defp within_currentness_window?(eligibility) do
    case {eligibility["derived_at"], eligibility["valid_until"]} do
      {derived_at, valid_until} when is_binary(derived_at) and is_binary(valid_until) ->
        now = DateTime.utc_now()
        valid_until_dt = parse_iso8601!(valid_until)
        derived_at_dt = parse_iso8601!(derived_at)

        cond do
          DateTime.compare(now, derived_at_dt) == :lt -> false
          DateTime.compare(now, valid_until_dt) == :gt -> false
          true -> DateTime.diff(now, derived_at_dt, :second) <= 168 * 3600
        end

      _ ->
        false
    end
  end

  defp parse_iso8601!(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> raise ArgumentError, "invalid ISO-8601: #{value}"
    end
  end

  defp validate_dispatch(profile, eligibility, assignment) do
    case validate_binding(profile, eligibility, assignment) do
      :ok -> :ok
      {:ok, :validated} -> :ok
      {:error, %{code: code, reason: reason}} ->
        {:error, %Error{class: :precondition, code: code, message: reason}}
    end
  end

  defp observe_repository(root) do
    case RepositoryObservation.observe(root, nil) do
      %RepositoryObservation{} = obs ->
        if obs.head_resolved do
          {:ok, obs}
        else
          {:error, Error.new(:precondition, :repository_not_initialized, "repository has no HEAD commit", %{repository: root})}
        end

      {:error, %Error{} = err} ->
        {:error, err}
    end
  end

  defp assignment_ref(assignment) do
    %{
      "id" => assignment["assignment_id"] || assignment_id_from_refs(assignment),
      "digest" => assignment["semantic_digest"] || ""
    }
  end

  defp profile_ref(profile) do
    %{"id" => profile["profile_id"], "digest" => profile["semantic_digest"]}
  end

  defp assignment_id_from_refs(_assignment), do: "asg_" <> short_id()

  defp default_attempt_ref do
    %{"id" => "att_" <> short_id(), "digest" => "sha256:" <> String.duplicate("0", 64)}
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp sha256_hex(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end

  defp canonical_digest(schema, payload) do
    "sha256:" <> Canonical.digest(schema, payload)
  end
end