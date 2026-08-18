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
    - Transport: Finch (v0.20) via `Finch.stream_while/5`. The adapter
      uses the bounded-receive path: `{:status, status}` arrives before
      any body materialization, body chunks arrive incrementally, and
      the adapter returns `{:halt, acc}` from the stream callback when
      the cumulative received byte count exceeds
      `@max_response_bytes` (1 MiB). OTP `:httpc` cannot satisfy both
      the canonical failure-class mapping and the bounded raw network
      receipt simultaneously under the KILN-M0-01 transport constraint.
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

  The `stream/2` callback below dispatches via Finch with the bounded
  `stream_while` receive path. The transport seam is exposed via
  `Application.get_env(:kiln, :minimax_transport, &default_finch_transport/3)`
  so tests can prove bounded transport behavior with a deterministic
  function returning canned response sequences, without ever touching
  the real network or the real operator credential.

  No retry, no fallback, no alternate provider. Exactly one dispatch
  attempt per `stream/2` call. The credential value is consumed inside
  the bearer header and never appears in any other field, log, artifact,
  or result.
  """

  @behaviour Kiln.Conformance.Provider

  alias Kiln.CandidateInvocation
  alias Kiln.Store.Canonical

  @endpoint "https://api.minimax.io/v1/chat/completions"
  @credential_env "MINIMAX_API_KEY"
  @max_response_bytes 1_048_576
  @default_model "MiniMax-M3"
  @finch_name Kiln.MinimaxFinch
  @default_timeout_ms 60_000

  @doc "Single endpoint URL (read-only). Not a credential."
  @spec endpoint() :: String.t()
  def endpoint, do: @endpoint

  @doc """
  The endpoint the production transport actually dispatches to.

  Defaults to `endpoint/0`. Override via
  `Application.put_env(:kiln, :minimax_endpoint, url)` for tests
  (e.g., loopback integration tests). The override is the same
  endpoint used by the actual `Finch.stream_while/5` dispatch.

  Note: the override is the runtime endpoint, not a credential. The
  credential resolution path is unchanged.
  """
  @spec transport_endpoint() :: String.t()
  def transport_endpoint do
    Application.get_env(:kiln, :minimax_endpoint, @endpoint)
  end

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
      perform_bounded_dispatch(request, credential, event_callback)
    end
  end

  @impl true
  def cancel(_term), do: :ok

  @doc """
  The bounded transport seam.

  The default (`default_finch_transport/3`) calls `Finch.stream_while/5`
  with a callback that observes status before the body materializes,
  accumulates body chunks incrementally, tracks the cumulative byte
  count, and returns `{:halt, acc}` when the next chunk would cross
  `@max_response_bytes`. Tests override this via
  `Application.put_env(:kiln, :minimax_transport, fn ...)` to provide
  canned response sequences without touching the real network.

  Contract for the transport function:

      fn(request, credential, opts) ::
        {:ok, %{status: pos_integer(), headers: [...], body: binary()}}
        | {:error, :oversize, received_bytes :: pos_integer()}
        | {:error, :finch_error, reason :: term()}

  `opts` is a keyword list containing at least `:timeout_ms` (used by
  the default Finch transport for `receive_timeout`).

  The transport function NEVER:
    - retries;
    - falls back to a different provider;
    - reads the credential from outside the function argument;
    - persists the credential in any side channel.
  """
  @spec transport_dispatch() :: (map(), String.t(), keyword() ->
                                     {:ok, map()} | {:error, atom(), term()})
  def transport_dispatch do
    case Application.get_env(:kiln, :minimax_transport) do
      nil -> &default_finch_transport/3
      fun when is_function(fun, 3) -> fun
    end
  end

  defp perform_bounded_dispatch(request, credential, event_callback) do
    opts = [timeout_ms: request.timeout_ms, max_bytes: @max_response_bytes]

    case safe_transport(transport_dispatch(), request, credential, opts) do
      {:ok, %{status: status, body: body, headers: _headers}} when status in 200..299 ->
        case enforce_bounded_receipt(body) do
          :ok ->
            event_callback.(%{
              status: :ok,
              body: body,
              request_digest: request.semantic_digest
            })

            {:ok, bounded_success_result(request, body, status, _headers)}

          {:error, _} = err ->
            err
        end

      {:ok, %{status: status}} ->
        {:error, normalized_http_failure(status)}

      {:error, :oversize, received_bytes} ->
        {:error,
         CandidateInvocation.terminal_result(:E_POLICY_REJECTION)
         |> Map.put(:details, %{
           reason: "response body exceeds bounded raw transport ceiling",
           received_bytes: received_bytes,
           ceiling_bytes: @max_response_bytes
         })}

      {:error, :disconnect, reason} ->
        {:error,
         CandidateInvocation.terminal_result(:E_CONNECTION_LOST)
         |> Map.put(:details, %{reason: inspect(reason)})}

      {:error, :finch_error, reason} ->
        {:error,
         CandidateInvocation.terminal_result(:E_CONNECTION_LOST)
         |> Map.put(:details, %{reason: inspect(reason)})}
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

  defp safe_transport(fun, request, credential, opts) do
    try do
      fun.(request, credential, opts)
    catch
      :error, _ -> {:error, :finch_error, :caught_error}
      :exit, _ -> {:error, :finch_error, :caught_exit}
      _kind, _ -> {:error, :finch_error, :caught_other}
    end
  end

  @doc """
  Default production transport: bounded Finch streaming with
  `Finch.stream_while/5`.

  The callback observes status before any body materialization,
  accumulates body chunks incrementally, tracks the cumulative byte
  count, and returns `{:halt, acc}` when the next chunk would cross
  `@max_response_bytes`. On HTTP/1, `:halt` closes the connection
  immediately. The partial body in `acc.body_chunks` is discarded.

  Properties proved:
    1. status available before/during body processing (no body
       materialization required to read status);
    2. incremental bounded body receipt (chunks accumulate);
    3. cumulative byte tracking;
    4. terminate receipt when bound is crossed;
    5. discard partial provider output after halt;
    6. never construct a body larger than `@max_response_bytes`;
    7. canonical failure mapping on oversize (`:E_POLICY_REJECTION`);
    8. transport error mapped to `:E_CONNECTION_LOST`;
    9. timeout firing mid-stream is captured by Finch's
       `receive_timeout` and surfaced as a transport error.
  """
  def default_finch_transport(request, credential, opts) do
    max_bytes = Keyword.get(opts, :max_bytes, @max_response_bytes)
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    finch_request =
      Finch.build(
        :post,
        transport_endpoint(),
        [
          {"authorization", "Bearer " <> credential},
          {"content-type", "application/json"},
          {"accept", "application/json"}
        ],
        encode_openai_compatible_body(request)
      )

    initial_acc = %{
      status: nil,
      headers: [],
      body_chunks: [],
      body_bytes: 0,
      too_large: false
    }

    handler = fn event, acc -> handle_finch_event(event, acc, max_bytes) end

    case Finch.stream_while(
           finch_request,
           @finch_name,
           initial_acc,
           handler,
           receive_timeout: timeout_ms
         ) do
      {:ok, %{too_large: true, body_bytes: bytes}} ->
        {:error, :oversize, bytes}

      {:ok, %{status: status, headers: headers, body_chunks: chunks}} ->
        body = chunks |> Enum.reverse() |> IO.iodata_to_binary()
        {:ok, %{status: status, headers: headers, body: body}}

      {:error, reason, _acc} ->
        {:error, :finch_error, reason}
    end
  end

  defp handle_finch_event({:status, status}, acc, _max_bytes) do
    {:cont, %{acc | status: status}}
  end

  defp handle_finch_event({:headers, headers}, acc, _max_bytes) do
    {:cont, %{acc | headers: headers}}
  end

  defp handle_finch_event({:data, chunk}, acc, max_bytes) do
    new_bytes = acc.body_bytes + byte_size(chunk)

    if new_bytes > max_bytes do
      # Bound crossed: halt immediately, discard partial body,
      # mark the oversize condition. The adapter normalizes this to
      # :E_POLICY_REJECTION. No further chunks are accumulated.
      {:halt, %{acc | too_large: true, body_bytes: new_bytes}}
    else
      {:cont, %{acc | body_chunks: [chunk | acc.body_chunks], body_bytes: new_bytes}}
    end
  end

  defp handle_finch_event({:trailers, _trailers}, acc, _max_bytes) do
    {:cont, acc}
  end

  @doc """
  Process a sequence of Finch stream events through the bounded receive logic.

  This is the same event handler that `default_finch_transport/3` installs
  into `Finch.stream_while/5`. It is exposed for direct testing of the
  bounded receive path with simulated Finch events, without needing a
  real Finch instance or a real HTTP server.

  Events are the same tuples Finch emits during streaming:
      {:status, pos_integer()}
      {:headers, [binary()]}
      {:data, binary()}
      {:trailers, [binary()]}

  Returns:
      {:ok, %{status: status, headers: headers, body: binary(), body_bytes: pos_integer()}}
      | {:halt, pos_integer()}  -- the byte count that triggered the halt

  The function is total: any event sequence is well-defined.
  """
  @spec process_stream_events([term()], pos_integer()) ::
          {:ok, map()} | {:halt, pos_integer()}
  def process_stream_events(events, max_bytes) when is_list(events) and is_integer(max_bytes) do
    initial_acc = %{
      status: nil,
      headers: [],
      body_chunks: [],
      body_bytes: 0,
      too_large: false
    }

    Enum.reduce_while(events, initial_acc, fn event, acc ->
      handle_finch_event(event, acc, max_bytes)
    end)
    |> case do
      %{too_large: true, body_bytes: bytes} -> {:halt, bytes}
      %{status: status, headers: headers, body_chunks: chunks, body_bytes: bytes} ->
        body = chunks |> Enum.reverse() |> IO.iodata_to_binary()
        {:ok, %{status: status, headers: headers, body: body, body_bytes: bytes}}
    end
  end

  defp bounded_success_result(request, body, _status, _headers) do
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
