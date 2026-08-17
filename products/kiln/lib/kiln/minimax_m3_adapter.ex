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

  ## Bounded provider implementation (KILN-M0-01 scope)

  The `stream/2` callback below dispatches via OTP `:httpc` with bounded
  options: an explicit request timeout (from `request.timeout_ms`, bounded
  1s..30min by the `CandidateInvocation` contract) and a strict response
  body receipt ceiling (`@max_response_bytes` = 1 MiB, deliberately
  distinct from the 16 MiB `Kiln.Artifact.max_byte_size/0` Artifact.Store
  ceiling so the two limits can be reasoned about independently). The raw
  transport ceiling rejects any response body that would exceed it before
  unbounded accumulation can occur.

  The dispatch function is injected via `Application.get_env/3` so tests can
  prove bounded transport behavior with a deterministic seam (a local function
  returning canned responses), without ever touching the real network or the
  real operator credential. In production, the default is `&:httpc.request/1`.

  No retry, no fallback, no alternate provider. Exactly one dispatch attempt
  per `stream/2` call. The credential value is consumed inside the bearer
  header and never appears in any other field, log, artifact, or result.
  """

  @behaviour Kiln.Conformance.Provider

  alias Kiln.CandidateInvocation
  alias Kiln.Store.Canonical

  @endpoint "https://api.minimax.io/v1/chat/completions"
  @credential_env "MINIMAX_API_KEY"
  @max_response_bytes 1_048_576
  @default_model "MiniMax-M3"

  @doc "Single endpoint URL (read-only). Not a credential."
  @spec endpoint() :: String.t()
  def endpoint, do: @endpoint

  @doc "The bounded raw transport receipt ceiling. Deliberately distinct from `Kiln.Artifact.max_byte_size/0`."
  @spec max_response_bytes() :: pos_integer()
  def max_response_bytes, do: @max_response_bytes

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
  def stream(%CandidateInvocation{} = request, event_callback)
      when is_function(event_callback, 1) do
    with {:ok, credential} <- fetch_credential() do
      dispatch_bounded(request, credential, event_callback)
    end
  end

  @impl true
  def cancel(_term), do: :ok

  @doc """
  Bounded dispatch path.

  - Explicit request timeout from `request.timeout_ms` (bounded 1s..30min by the
    `CandidateInvocation` contract).
  - Bearer credential header built from the resolved env value; the value
    itself never appears in any other field, log, artifact, or result.
  - `body_format: :binary` so the body is received as a single binary we
    can size-check before any further accumulation.
  - Response body size-checked against `@max_response_bytes`; the first byte
    over the limit is rejected with `E_POLICY_REJECTION` before unbounded
    accumulation can occur.
  - All non-2xx responses normalized to canonical failure classes.
  - No retry, no fallback, no alternate provider.
  """
  defp dispatch_bounded(request, credential, event_callback) do
    with {:ok, bounded_body} <- perform_bounded_dispatch(request, credential),
         :ok <- enforce_bounded_receipt(bounded_body) do
      event_callback.(%{
        status: :ok,
        body: bounded_body,
        request_digest: request.semantic_digest
      })

      {:ok, bounded_success_result(request, bounded_body)}
    else
      {:error, _} = err -> err
    end
  end

  defp perform_bounded_dispatch(request, credential) do
    timeout_ms = request.timeout_ms
    body = encode_openai_compatible_body(request)

    http_opts = [
      url: @endpoint,
      method: :post,
      timeout: timeout_ms,
      connect_timeout: timeout_ms,
      body: body,
      headers: [
        {"authorization", "Bearer " <> credential},
        {"content-type", "application/json"},
        {"accept", "application/json"}
      ],
      body_format: :binary
    ]

    dispatch = http_dispatch()

    case safe_dispatch(dispatch, http_opts) do
      {:ok, {{_http_version, 200, _reason}, _headers, body}} when is_binary(body) ->
        {:ok, body}

      {:ok, {{_http_version, status, _reason}, _headers, _body}} when is_integer(status) ->
        {:error, normalized_http_failure(status)}

      {:ok, {_status_line, _headers, body}} when is_binary(body) ->
        {:ok, body}

      {:error, _reason} ->
        {:error, CandidateInvocation.terminal_result(:E_CONNECTION_LOST)}

      _other ->
        {:error, CandidateInvocation.terminal_result(:E_UNKNOWN)}
    end
  end

  defp safe_dispatch(dispatch, http_opts) do
    try do
      dispatch.(http_opts)
    catch
      :error, _ -> {:error, CandidateInvocation.terminal_result(:E_CONNECTION_LOST)}
      :exit, _ -> {:error, CandidateInvocation.terminal_result(:E_CONNECTION_LOST)}
      _kind, _ -> {:error, CandidateInvocation.terminal_result(:E_UNKNOWN)}
    end
  end

  defp enforce_bounded_receipt(body) do
    if byte_size(body) <= @max_response_bytes do
      :ok
    else
      {:error,
       CandidateInvocation.terminal_result(:E_POLICY_REJECTION)
       |> Map.put(:details, %{
         reason: "response body exceeds bounded raw transport ceiling",
         received_bytes: byte_size(body),
         ceiling_bytes: @max_response_bytes
       })}
    end
  end

  defp bounded_success_result(request, body) do
    %{
      status: :ok,
      schema: request.schema,
      body_digest: "sha256:" <> Base.encode16(:crypto.hash(:sha256, body), case: :lower),
      body_bytes: byte_size(body),
      body: body,
      failure_classification: request.failure_classification
    }
  end

  # 4xx / 5xx → canonical failure classes. No body bytes are returned; the
  # secret value never left the process, and no response body is ever
  # embedded in a result.
  defp normalized_http_failure(401), do: CandidateInvocation.terminal_result(:E_PROVIDER_DENIED)
  defp normalized_http_failure(403), do: CandidateInvocation.terminal_result(:E_PROVIDER_DENIED)
  defp normalized_http_failure(408), do: CandidateInvocation.terminal_result(:E_TIMEOUT)
  defp normalized_http_failure(429), do: CandidateInvocation.terminal_result(:E_POLICY_REJECTION)
  defp normalized_http_failure(status) when status >= 400 and status < 500,
    do: CandidateInvocation.terminal_result(:E_PROVIDER_DENIED)

  defp normalized_http_failure(status) when status >= 500 and status < 600,
    do: CandidateInvocation.terminal_result(:E_RUNTIME_UNAVAILABLE)

  defp normalized_http_failure(_), do: CandidateInvocation.terminal_result(:E_UNKNOWN)

  defp encode_openai_compatible_body(request) do
    JSON.encode!(%{
      model: @default_model,
      invocation_id: request.invocation_id,
      mode: Atom.to_string(request.mode),
      profile_ref: request.profile_ref,
      context_manifest_ref: request.context_manifest_ref,
      tool_policy_ref: request.tool_policy_ref,
      timeout_ms: request.timeout_ms,
      output_contract: Atom.to_string(request.output_contract),
      stream: false
    })
  end

  defp fetch_credential do
    case System.get_env(@credential_env) do
      nil -> {:error, CandidateInvocation.terminal_result(:E_RUNTIME_UNAVAILABLE)}
      "" -> {:error, CandidateInvocation.terminal_result(:E_RUNTIME_UNAVAILABLE)}
      credential when is_binary(credential) -> {:ok, credential}
      _ -> {:error, CandidateInvocation.terminal_result(:E_RUNTIME_UNAVAILABLE)}
    end
  end

  defp http_dispatch do
    Application.get_env(:kiln, :minimax_http_dispatch, &:httpc.request/1)
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
    case :application.get_key(:kiln, :dir) do
      {:ok, dir} -> Path.join([dir, "..", "..", "..", "lib"]) |> Path.expand()
      _ -> Path.expand("lib", File.cwd!())
    end
  end
end
