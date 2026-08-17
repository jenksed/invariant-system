defmodule Kiln.MinimaxM3Adapter do
  @moduledoc """
  MiniMax M3 provider adapter implementing `Kiln.Conformance.Provider`.

  Single bounded adapter identity for the MiniMax M3 runtime (OpenAI-compatible
  chat completions). Adapter identity (module, endpoint family, contract version)
  is identical between `production` and `qualification` modes (P02-D020); mode
  changes authority and limits only.

  Per the accepted KILN-M0-01 plan and `Kiln.CandidateInvocation` schema:

    - Endpoint: `https://api.minimax.io/v1/chat/completions` (single,
      streaming, OpenAI-compatible chat completions).
    - Transport: OTP `:httpc` only. STOP if `:httpc` is demonstrably
      insufficient for streaming SSE — do NOT add a new Mix dependency.
    - Credentials: presence-only via env var `MINIMAX_API_KEY` through one
      private credential-resolution function. The value never enters
      Context, Artifact, Evidence, manifests, logs, or result payloads
      (negative-tested).
    - Failure mode: terminal `E_RUNTIME_UNAVAILABLE` when the credential
      is absent; no dispatch attempted.
    - No retry, no fallback, no alternate provider.

  Adapter `implementation_digest/0` is computed from the source bytes of this
  module, `Kiln.CandidateInvocation`, and the canonical schema digest; it is
  stable across BEAM rebuilds unless the source bytes change.
  """

  @behaviour Kiln.Conformance.Provider

  alias Kiln.CandidateInvocation
  alias Kiln.Store.Canonical

  @endpoint "https://api.minimax.io/v1/chat/completions"
  @credential_env "MINIMAX_API_KEY"

  @doc "Single endpoint URL (read-only). Not a credential."
  @spec endpoint() :: String.t()
  def endpoint, do: @endpoint

  @doc "Compute the adapter implementation digest over the source bytes of this module, `Kiln.CandidateInvocation`, and the schema digest. Stable across BEAM rebuilds unless source bytes change."
  @spec implementation_digest() :: String.t()
  def implementation_digest do
    schema_id = CandidateInvocation.schema_id()
    schema_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, schema_id), case: :lower)

    adapter_source = read_source!(__MODULE__)
    candidate_source = read_source!(CandidateInvocation)

    "sha256:" <>
      Base.encode16(
        :crypto.hash(:sha256, adapter_source <> candidate_source <> schema_digest),
        case: :lower
      )
  end

  @impl true
  def stream(%CandidateInvocation{} = request, _event_callback) do
    case credential_present?() do
      false ->
        {:error, CandidateInvocation.terminal_result(:E_RUNTIME_UNAVAILABLE)}

      true ->
        # Dispatch is intentionally not implemented in this bounded M0 slice:
        # live network invocation would expand scope beyond the authorized
        # Candidate Invocation contract. The acceptance unit is the bounded
        # request envelope, the canonical encoding, and the credential-
        # presence terminal. Live dispatch belongs to a later authorized
        # ticket; this adapter returns terminal :E_TERMINAL_RESULT after
        # credential validation.
        canonical_request = canonicalize_request(request)
        canonical_digest = Canonical.digest(request.schema, canonical_request)

        if canonical_digest == request.semantic_digest do
          {:error, CandidateInvocation.terminal_result(:E_TERMINAL_RESULT)}
        else
          {:error, CandidateInvocation.terminal_result(:E_MALFORMED_OUTPUT)}
        end
    end
  end

  @impl true
  def cancel(_term), do: :ok

  # --- private ---

  defp credential_present? do
    case System.get_env(@credential_env) do
      nil -> false
      "" -> false
      _value -> true
    end
  end

  defp canonicalize_request(%CandidateInvocation{} = request) do
    %{
      invocation_id: request.invocation_id,
      mode: Atom.to_string(request.mode),
      profile_ref: request.profile_ref,
      context_manifest_ref: request.context_manifest_ref,
      tool_policy_ref: request.tool_policy_ref,
      timeout_ms: request.timeout_ms,
      output_contract: Atom.to_string(request.output_contract),
      failure_classification: request.failure_classification
    }
  end

  defp read_source!(module) do
    rel =
      module
      |> Atom.to_string()
      |> String.replace_prefix("Elixir.", "")
      |> String.split(".")
      |> Enum.map_join("/", &Macro.underscore/1)
      |> Kernel.<>(".ex")

    path = Path.join(source_root(), rel)

    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> raise "could not read adapter source #{path}: #{inspect(reason)}"
    end
  end

  defp source_root do
    # Locate the lib/ directory of the current Mix project.
    # :application.get_key(:kiln, :dir) returns the ebin path
    # (_build/<env>/lib/kiln/ebin), so go up 3 levels to reach lib/.
    case :application.get_key(:kiln, :dir) do
      {:ok, dir} -> Path.join([dir, "..", "..", "..", "lib"]) |> Path.expand()
      _ -> Path.expand("lib", File.cwd!())
    end
  end
end
