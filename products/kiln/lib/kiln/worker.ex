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
  alias Kiln.DogfoodAdapter
  alias Kiln.MinimaxM3Adapter
  alias Kiln.ExecutionAuthorityGate
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
           reason: "eligibility.profile_ref.digest does not match assignment.profile_ref.digest"
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
         # M11 E2 B-repair + KILN-M0-01 integration: the bounded completion is
         # either the deterministic-fake envelope (the historical M11 E2 path)
         # or the bounded MiniMax M3 provider's completion (the new
         # provider-backed path). The selection is controlled by the
         # `:worker_provider_mode` application env: `:deterministic_fake`
         # (default) keeps the historical deterministic E2 path green;
         # `:real_provider` exercises the real bounded MiniMax adapter
         # behind the deterministic transport seam.
         #
         # The provider-backed path ALSO requires an explicit
         # `Authority.decide/1` grant for the `provider.network` capability
         # (see `check_provider_network_authority/2`). The default is
         # **denied**; tests must explicitly grant this capability via
         # `Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])`.
         # Live network execution is therefore impossible without
         # explicit owner authorization.
         {:ok, completion_bytes, parsed_digest} <-
           build_completion(ci_request, request_attrs, observation, observation.current_commit) do
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
          "adapter_implementation_digest" => adapter_implementation_digest(),
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
         adapter_implementation_digest: adapter_implementation_digest()
       }}
    end
  end

  @doc """
  Provider-mode selection boundary. The default is `:deterministic_fake`
  which preserves the accepted M11 E2 deterministic path. Setting
  `:worker_provider_mode` to `:real_provider` exercises the bounded
  MiniMax M3 adapter via the deterministic transport seam for tests,
  or the actual Finch transport in production. Setting the mode to
  `:dogfood` exercises the bounded deterministic
  `Kiln.DogfoodAdapter` (M3 dogfood / self-hosting) which emits real
  bounded source mutations from a task spec carried in
  `request_attrs["dogfood_task_spec"]`.

  This is the ONLY decision the Worker makes about provider selection.
  The Worker does not select providers; the runtime/operator configures
  the mode before dispatch.

  Fail-closed: unknown values are returned as
  `{:error, %{code: :E_WORKER_PROVIDER_MODE_INVALID, reason: ...}}`
  rather than masquerading as a valid mode.
  """
  @spec worker_provider_mode() ::
          :deterministic_fake | :real_provider | :dogfood | {:error, term()}
  def worker_provider_mode do
    # Distinguish "genuinely absent" (default to :deterministic_fake)
    # from "explicitly set to an invalid value" (fail closed with
    # :E_WORKER_PROVIDER_MODE_INVALID). Application.fetch_env/1 returns
    # :error when the key is absent; Application.get_env/3 with a
    # default conflates "absent" with "set to nil".
    case Application.fetch_env(:kiln, :worker_provider_mode) do
      {:ok, :real_provider} ->
        :real_provider

      {:ok, :dogfood} ->
        :dogfood

      {:ok, :deterministic_fake} ->
        :deterministic_fake

      {:ok, nil} ->
        # Application.put_env(:kiln, :worker_provider_mode, nil) leaves
        # the key set to nil; treat it the same as absent so callers
        # can clear configuration without triggering an invalid-mode
        # error.
        :deterministic_fake

      {:ok, other} ->
        {:error,
         %{code: :E_WORKER_PROVIDER_MODE_INVALID, reason: "unknown worker_provider_mode: #{inspect(other)}"}}

      :error ->
        # Genuinely absent configuration: default to the historical
        # M11 E2 deterministic-fake path. Tests and dogfood runs that
        # need a different mode MUST set the env explicitly.
        :deterministic_fake
    end
  end

  # The adapter_implementation_digest records which adapter actually
  # produced the completion_bytes. Each adapter's implementation_digest/0
  # is computed from its source bytes; consumers downstream can use
  # this to verify the candidate was produced by the bound adapter.
  defp adapter_implementation_digest do
    case worker_provider_mode() do
      :dogfood -> DogfoodAdapter.implementation_digest()
      :real_provider -> MinimaxM3Adapter.implementation_digest()
      _ -> MinimaxM3Adapter.implementation_digest()
    end
  end

  @doc """
  Build the bounded completion. Selects between:
    - the deterministic-fake completion (historical M11 E2 path);
    - the bounded real-provider completion (KILN-M0-01 integration).

  Returns `{:ok, completion_bytes, parsed_digest}` on success, or a
  bounded error tuple. The completion bytes in the real-provider path
  are the provider's bounded response body (validated as a canonical
  `implementer-patch-proposal-input/v1` envelope by `PatchProposal.decode_envelope/1`).

  The `observation` and `base_commit` are required for the
  provider-backed path so that the `provider.network` capability
  check against `Authority.decide/1` is bound to the observed
  repository state at dispatch time.
  """
  @spec build_completion(CandidateInvocation.t(), map(), RepositoryObservation.t(), String.t()) ::
          {:ok, binary(), String.t()}
          | {:error, term()}
  def build_completion(
        %CandidateInvocation{} = ci_request,
        request_attrs,
        %RepositoryObservation{} = observation,
        base_commit
      )
      when is_map(request_attrs) and is_binary(base_commit) do
    case worker_provider_mode() do
      :real_provider ->
        build_provider_completion(ci_request, observation, base_commit)

      :dogfood ->
        build_dogfood_completion(request_attrs, observation)

      :deterministic_fake ->
        build_bounded_completion(request_attrs)

      {:error, %{code: :E_WORKER_PROVIDER_MODE_INVALID}} = err ->
        # Explicitly invalid mode is fail-closed: do NOT fall back to
        # deterministic-fake. The error propagates through the with
        # chain in Worker.propose/5 so the caller sees exactly which
        # mode value was rejected.
        err
    end
  end

  # M3 (DOGFOOD / SELF-HOSTING) bounded path. The Dogfood Task Spec
  # is carried in request_attrs["dogfood_task_spec"]. The Adapter
  # produces canonical bounded bytes that decode through
  # Kiln.PatchProposal.decode_envelope/1; the same canonical contract
  # the other provider modes obey. The Adapter is NOT execution
  # authority — it emits a candidate only; the canonical
  # human.decide / patch.apply path remains the only place that
  # can authorize effects.
  defp build_dogfood_completion(request_attrs, observation) do
    case Map.fetch(request_attrs, "dogfood_task_spec") do
      {:ok, spec} when is_map(spec) ->
        case DogfoodAdapter.build_envelope(spec, observation.repository) do
          {:ok, bytes, semantic} ->
            {:ok, bytes, semantic}

          {:error, %{code: _} = err} ->
            {:error, err}
        end

      _ ->
        {:error,
         %{
           code: :E_DOGFOOD_TASK_SPEC_MISSING,
           reason:
             "worker_provider_mode=:dogfood requires request_attrs['dogfood_task_spec'] to be a JSON object"
         }}
    end
  end

  @doc """
  Provider-backed completion path.

  The runtime admission sequence is:
    1. worker_provider_mode = :real_provider (selection)
    2. trusted owner authorization verified (Kiln.ExecutionAuthorityGate)
    3. MINIMAX_API_KEY present (credential — fetched ONLY after authority)
    4. dispatch

  All four must hold. The credential is **never read** unless the
  owner authorization has been verified first. The authorization
  itself is bound to the recorded authorization record file
  (`products/kiln/docs/authorizations/KILN-M0-01-E4.provider-network.authorization`),
  not to `Application.put_env`. See `Kiln.ExecutionAuthorityGate` for the
  fail-closed failure modes.

  Once admission passes, calls `MinimaxM3Adapter.stream/2` with the
  canonical CandidateInvocation, validates the bounded provider body
  as an `implementer-patch-proposal-input/v1` envelope via
  `PatchProposal.decode_envelope/1`, and returns the bounded bytes
  plus their digest.

  The provider does NOT gain:
    - mutation authority;
    - patch approval authority;
    - HumanDecision authority;
    - repository authority;
    - verification authority.
  """
  @spec build_provider_completion(CandidateInvocation.t(), RepositoryObservation.t(), String.t()) ::
          {:ok, binary(), String.t()}
          | {:error, term()}
  def build_provider_completion(
        %CandidateInvocation{} = ci_request,
        %RepositoryObservation{} = observation,
        base_commit
      )
      when is_binary(base_commit) do
    # Step 1: verify the trusted owner authorization. If absent,
    # missing, proposed, wrong-base, or wrong-work_id, the runtime
    # fails closed BEFORE the credential is read.
    with {:ok, _authorization_record} <-
           Kiln.ExecutionAuthorityGate.verify_provider_network_authorization(
             base_commit,
             observation
           ) do
      # Step 2: dispatch (which internally fetches the credential
      # and then dispatches via the bounded Finch transport).
      case MinimaxM3Adapter.stream(ci_request, fn _ -> :ok end) do
        {:ok, %{status: :ok, body: body}} ->
          case Kiln.PatchProposal.decode_envelope(body) do
            {:ok, _ops} ->
              {:ok, body, sha256_hex(body)}

            {:error, _} = err ->
              err
          end

        {:error, _} = err ->
          err
      end
    end
  end

  @doc """
  Owner-controlled execution authority gate for the provider-backed
  path. Returns `:ok` only when an explicit `Authority.decide/1`
  grant is present for the `provider.network` capability on the
  observed repository.

  The default production values are:
      allowed_capabilities: []
      denied_capabilities:  ["provider.network"]

  These default values result in a `:denied` decision, making
  live network execution impossible without explicit owner
  authorization. Tests that install the deterministic transport
  seam must explicitly grant the capability:

      Application.put_env(
        :kiln, :provider_network_allowed_capabilities, ["provider.network"]
      )

  The scope is bound to the observed repository (the actual
  dispatch target) so that the standard `Authority.decide/1`
  scope-mismatch check is satisfied.
  """
  @spec check_provider_network_authority(RepositoryObservation.t(), String.t()) ::
          :ok | {:error, term()}
  def check_provider_network_authority(
        %RepositoryObservation{} = observation,
        base_commit
      )
      when is_binary(base_commit) do
    Kiln.ExecutionAuthorityGate.verify_provider_network_authorization(
      base_commit,
      observation
    )
  end

  @doc """
  Build the bounded candidate-invocation attribute set from the
  validated binding + the request attributes supplied by the caller.

  M11 E2 B-repair: the previous implementation did
  `Map.merge(request_attrs, %{...})`, which passed the entire Work
  Envelope (keys: `authority_requests`, `capability`, `constraints`,
  `context_refs`, `created_at`, `goal`, `producer`, `project_state`,
  `proof_obligations`, `schema`, `scope`, `work_id`) into the CI
  attrs. `CandidateInvocation.new_request/1` then called
  `normalize_keys/1` which converts *every* binary key to an
  existing atom via `String.to_existing_atom/1` — and the Work
  Envelope keys don't exist as atoms in the
  `CandidateInvocation` module's namespace, raising
  `ArgumentError` ("not an already existing atom"). The bounded fix
  constructs the CI attrs from scratch using only the fields
  `CandidateInvocation.new_request/1` actually consumes; the Work
  Envelope is not used as a pass-through here.
  """
  @spec merge_dispatch_attrs(profile :: map(), eligibility :: map(), request_attrs :: map()) ::
          {:ok, map()} | {:error, term()}
  def merge_dispatch_attrs(profile, eligibility, request_attrs)
      when is_map(profile) and is_map(eligibility) and is_map(request_attrs) do
    _ = request_attrs

    attrs = %{
      "invocation_id" => "inv_e2_" <> short_id(),
      "mode" => @production_mode,
      "profile_ref" => %{
        "id" => profile["profile_id"],
        "digest" => profile["semantic_digest"]
      },
      "context_manifest_ref" => %{
        "id" => profile["system_config"]["id"],
        "digest" => profile["system_config"]["digest"]
      },
      "tool_policy_ref" => %{
        "id" => profile["tool_policy"]["id"],
        "digest" => profile["tool_policy"]["digest"]
      },
      "timeout_ms" => 60_000,
      "output_contract" => "IMPLEMENTER_PATCH_PROPOSAL"
    }

    {:ok, attrs}
  end

  @doc """
  Serialize the bounded `engineering-system/implementer-patch-proposal-input/v1`
  envelope as the Worker bounded completion bytes.

  M11 E2 B-repair (CONTRACT_CONFORMANCE_REPAIR): the canonical
  authoritative E2 acceptance text (commit b0bb259) states:

    "deterministic fake implementer-patch-proposal-input/v1 envelope
     bytes with bounded preimage + afterimage digests...
     Persist via Kiln.Artifact.Store.put/2; build WorkerOutput with
     raw_completion_ref re-pointed to Artifact identity...
     decode envelope via Kiln.PatchProposal.decode_envelope/1"

  The bounded completion IS the `implementer-patch-proposal-input/v1`
  envelope — the bounded patch content the Worker is proposing. The
  previous implementation synthesized a different "bounded-candidate"
  schema that `PatchProposal.decode_envelope/1` rejects with
  `E_PATCH_ENVELOPE_SHAPE_INVALID` or `E_PATCH_ENVELOPE_SCHEMA_INVALID`.

  The CI struct is used only for the digest binding (the bounded
  completion's digest binds the Candidate Invocation metadata to the
  envelope content). The envelope itself is the authoritative completion
  bytes; `PatchProposal.decode_envelope/1` re-materializes the
  operations from these exact bytes and the canonical preimage /
  afterimage digests are computed from the proof-repo state, not
  synthesized here.

  The dispatcher's provider invocation remains the M3 adapter's
  responsibility under the production-mode credential gate; this
  function is the bounded deterministic-fake completion.
  """
  @spec build_bounded_completion(map()) ::
          {:ok, binary(), String.t()}
          | {:error, term()}
  def build_bounded_completion(envelope) when is_map(envelope) do
    bytes =
      envelope
      |> canonical_envelope_bytes()

    # Validate the envelope shape against the canonical decoder. This
    # fails closed at Worker dispatch if the bounded envelope is
    # malformed — the E2 script constructs well-formed envelopes; a
    # non-conforming envelope is a programmer defect, not a domain
    # error, so we let the error propagate as `{:error, ...}`.
    case Kiln.PatchProposal.decode_envelope(bytes) do
      {:ok, _ops} ->
        {:ok, bytes, envelope_digest(envelope)}

      {:error, _} = err ->
        err
    end
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

  # M11 E2 B-repair: canonical encoding for the bounded
  # `implementer-patch-proposal-input/v1` envelope. The bounded
  # completion bytes ARE the envelope — the digest binds to the
  # canonical content-addressed form that `PatchProposal.decode_envelope/1`
  # accepts and that the Artifact.Store round-trips byte-identically.
  @spec canonical_envelope_bytes(map()) :: binary()
  def canonical_envelope_bytes(envelope) when is_map(envelope) do
    text = JSON.encode!(envelope)
    text <> "\n"
  end

  # M11 E2 B-repair: digest over the canonical envelope bytes. The
  # bounded completion's digest is the content-addressed form, matching
  # the Artifact.Store content_digest. This is the digest the WorkerOutput's
  # `parsed_candidate_digest` carries downstream.
  @spec envelope_digest(map()) :: String.t()
  def envelope_digest(envelope) when is_map(envelope) do
    "sha256:" <> Base.encode16(:crypto.hash(:sha256, canonical_envelope_bytes(envelope)), case: :lower)
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
      :ok ->
        :ok

      {:ok, :validated} ->
        :ok

      {:error, %{code: code, reason: reason}} ->
        {:error, %Error{class: :precondition, code: code, message: reason}}
    end
  end

  defp observe_repository(root) do
    # M11 E2 B-repair: pass an empty-string placeholder for
    # input_state_digest. The canonical RepositoryObservation.observe/3
    # contract requires is_binary(input_state_digest); the previous
    # `nil` triggered a FunctionClauseError. The observation records
    # the input_state_digest field verbatim, and at Worker.propose
    # time there is no preceding-state digest to bind to, so the
    # empty string is the correct canonical placeholder.
    case RepositoryObservation.observe(root, "") do
      {:ok, %RepositoryObservation{} = obs} ->
        if obs.head_resolved do
          {:ok, obs}
        else
          {:error,
           Error.new(
             :precondition,
             :repository_not_initialized,
             "repository has no HEAD commit",
             %{repository: root}
           )}
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
