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

  # The single canonical-emission function the model is forced to call.
  # Its `arguments` field is a JSON string carrying the canonical
  # `engineering-system/implementer-patch-proposal-input/v1` envelope.
  # The host does NOT execute this function — it decodes the arguments
  # and passes them to `Kiln.PatchProposal.decode_envelope/1`.
  @canonical_function_name "kiln_emit_candidate_envelope"
  @canonical_envelope_schema_id "engineering-system/implementer-patch-proposal-input/v1"

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
        with :ok <- enforce_bounded_receipt(body),
             {:ok, envelope_bytes} <- decode_provider_response_wrapper(body) do
          event_callback.(%{
            status: :ok,
            body: envelope_bytes,
            request_digest: request.semantic_digest
          })

          {:ok, bounded_success_result(request, envelope_bytes, status, _headers)}
        else
          {:error, %{code: :E_MALFORMED_OUTPUT} = malformed} ->
            # The body was within bounds but the wrapper structure or
            # tool_call was invalid. Normalize to a terminal canonical
            # failure class so the upstream sees a uniform error shape.
            {:error,
             CandidateInvocation.terminal_result(:E_MALFORMED_OUTPUT)
             |> Map.put(:details, malformed)}

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
      stream: false,
      messages: build_bounded_messages(request),
      tools: build_canonical_tools(),
      tool_choice: "required"
    })
  end

  # Construct the bounded model-facing context as a single user message.
  # The model reads this message to understand what bounded artifact to
  # produce via the canonical-emission function call. The context is
  # bounded: it carries only the dispatch identity, output contract,
  # and context manifest reference — no credential, no evidence, no
  # mutation authority.
  defp build_bounded_messages(request) do
    [
      %{
        role: "user",
        content: bounded_context_text(request)
      }
    ]
  end

  defp bounded_context_text(request) do
    objective_line =
      case Map.get(request, :engineering_objective) do
        nil -> ""
        obj -> "\nengineering_objective: #{obj}"
      end

    """
    Bounded dispatch context.

    You are operating inside a bounded Kiln dispatch. Produce a single
    canonical envelope by calling the function #{@canonical_function_name}.
    Do not include any other text, reasoning, or function calls.

    output_contract: #{Atom.to_string(request.output_contract)}
    envelope_schema: #{@canonical_envelope_schema_id}
    invocation_id: #{request.invocation_id}
    context_manifest_ref: #{inspect(request.context_manifest_ref)}#{objective_line}
    """
  end

  # Exactly one canonical-emission function. The schema describes the
  # canonical envelope structure the model must produce. Validation
  # is authoritative at `Kiln.PatchProposal.decode_envelope/1`; this
  # schema is provider-facing guidance only.
  #
  # M11 E4 representation-repair: the per-operation post-image is emitted
  # by the model as a line-array (`after_image_lines`) plus a trailing-newline
  # flag (`final_newline`) rather than as a single escaped string. The
  # adapter deterministically translates this provider-private representation
  # into the canonical `after_image_bytes` bytes form inside
  # `translate_envelope_to_canonical/1` BEFORE returning envelope bytes to
  # the bounded dispatch. The downstream canonical envelope contract
  # (engineering-system/implementer-patch-proposal-input/v1) continues to
  # carry `after_image_bytes` only; `after_image_lines` and `final_newline`
  # are provider-private and never leak.
  defp build_canonical_tools do
    [
      %{
        type: "function",
        function: %{
          name: @canonical_function_name,
          description:
            "Emit the canonical Kiln patch-proposal envelope. " <>
              "Arguments must be a JSON object with schema=" <>
              @canonical_envelope_schema_id <>
              " and a non-empty operations array. For each operation, " <>
              "emit the post-image as `after_image_lines` (a JSON array of " <>
              "strings, one entry per source line; the literal characters " <>
              "inside each string ARE that line's exact bytes — DO NOT " <>
              "escape `\\n` or `\\t` inside the array entries, they mean " <>
              "literal backslash + n / backslash + t characters, NOT " <>
              "newlines or tabs) plus `final_newline` (boolean: emit a " <>
              "trailing newline byte after the joined lines?). The " <>
              "adapter joins lines with `\\n` and appends the optional " <>
              "trailing newline to produce the canonical bytes.",
          parameters: %{
            type: "object",
            properties: %{
              schema: %{
                type: "string",
                const: @canonical_envelope_schema_id
              },
              operations: %{
                type: "array",
                minItems: 1,
                items: %{
                  type: "object",
                  properties: %{
                    op: %{
                      type: "string",
                      enum: ["add", "replace", "delete"]
                    },
                    path: %{
                      type: "string"
                    },
                    expected_before_digest: %{
                      type: "string"
                    },
                    mode: %{
                      type: "string",
                      const: "100644"
                    },
                    after_image_lines: %{
                      type: "array",
                      items: %{"type" => "string"},
                      minItems: 1,
                      description:
                        "Provider-private line-array. Each entry is the " <>
                          "EXACT bytes of one source line. Do NOT escape " <>
                          "\\n or \\t inside entries (they mean literal " <>
                          "characters). Empty lines are valid."
                    },
                    final_newline: %{
                      type: "boolean",
                      description:
                        "Whether to emit a trailing newline byte after " <>
                          "the joined lines. Default true."
                    }
                  },
                  required: ["op", "path", "after_image_lines"]
                }
              }
            },
            required: ["schema", "operations"]
          }
        }
      }
    ]
  end

  @doc """
  Decode a bounded MiniMax response wrapper into the canonical envelope bytes.

  Validates:
    - body parses as JSON
    - `choices` is a non-empty list with exactly one element
    - `choices[0].message.tool_calls` is a non-empty list with exactly one element
    - `tool_calls[0].type` equals `"function"`
    - `tool_calls[0].function.name` equals the canonical function name
    - `tool_calls[0].function.arguments` is a JSON string

  Returns:
    `{:ok, envelope_bytes}` on success — `envelope_bytes` are the decoded
    canonical envelope as a JSON-encoded binary, ready for
    `Kiln.PatchProposal.decode_envelope/1`.
    `{:error, %{code: atom(), reason: atom()}}` on any validation failure.
  """
  @spec decode_provider_response_wrapper(binary()) ::
          {:ok, binary()} | {:error, map()}
  def decode_provider_response_wrapper(body) when is_binary(body) do
    with {:ok, parsed} <- safe_json_decode(body, :wrapper_not_json) do
      validate_wrapper_structure(parsed)
    end
  end

  defp validate_wrapper_structure(%{"choices" => choices}) when is_list(choices) do
    case choices do
      [single] ->
        validate_single_choice(single)

      [] ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :empty_choices}}

      _multiple ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :multiple_choices}}
    end
  end

  defp validate_wrapper_structure(_), do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_choices}}

  defp validate_single_choice(%{"message" => message}) when is_map(message) do
    case Map.get(message, "tool_calls") do
      [single] ->
        validate_single_tool_call(single)

      [] ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :empty_tool_calls}}

      nil ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_tool_calls}}

      _multiple ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :multiple_tool_calls}}
    end
  end

  defp validate_single_choice(_), do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_message}}

  defp validate_single_tool_call(%{"type" => "function", "function" => function})
       when is_map(function) do
    case Map.get(function, "name") do
      @canonical_function_name ->
        validate_arguments(Map.get(function, "arguments"))

      _other ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :unknown_function_name}}
    end
  end

  defp validate_single_tool_call(_), do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :wrong_tool_type}}

  defp validate_arguments(args) when is_binary(args) do
    case safe_json_decode(args, :arguments_not_json) do
      {:ok, decoded} when is_map(decoded) ->
        # If the provider emitted canonical `after_image_bytes` (no
        # provider-private representation), preserve the original
        # argument bytes verbatim to keep byte-level isomorphism with
        # `Worker.canonical_envelope_bytes/1`'s output (which includes a
        # trailing newline). Re-encoding via `JSON.encode!/1` would
        # strip that trailing newline and break isomorphism.
        if envelope_uses_only_canonical_bytes?(decoded) do
          {:ok, args}
        else
          # M11 E4 representation-repair: the provider emitted the
          # provider-private line-array representation, so we
          # deterministically translate it to canonical bytes and
          # append the canonical trailing newline. Then the
          # pre-approval Elixir-parseability gate runs.
          with {:ok, canonical} <- translate_envelope_to_canonical(decoded),
               :ok <- validate_envelope_post_images_parseable(canonical) do
            encoded = JSON.encode!(canonical) <> "\n"
            {:ok, encoded}
          end
        end

      {:ok, _not_map} ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :arguments_not_object}}

      {:error, _} = err ->
        err
    end
  end

  defp validate_arguments(_), do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_arguments}}

  defp envelope_uses_only_canonical_bytes?(envelope) when is_map(envelope) do
    ops =
      Map.get(envelope, "operations") || Map.get(envelope, :operations) || []

    Enum.all?(ops, fn op when is_map(op) ->
      has_canonical_representation?(op) and not has_provider_representation?(op)
    end)
  end

  # Translate the provider-private line-array representation to canonical
  # `after_image_bytes`. Idempotent: if the provider already produced
  # `after_image_bytes`, the operation is returned unchanged.
  defp translate_envelope_to_canonical(envelope) when is_map(envelope) do
    ops_in = Map.get(envelope, "operations") || Map.get(envelope, :operations) || []

    case Enum.reduce_while(ops_in, {:ok, []}, fn op, {:ok, acc} ->
           case translate_operation_to_canonical(op) do
             {:ok, translated} -> {:cont, {:ok, [translated | acc]}}
             {:error, _} = err -> {:halt, err}
           end
         end) do
      {:ok, translated_ops} ->
        {:ok, Map.put(envelope, "operations", Enum.reverse(translated_ops))}

      err ->
        err
    end
  end

  defp translate_envelope_to_canonical(_), do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :envelope_not_object}}

  defp translate_operation_to_canonical(op) when is_map(op) do
    cond do
      has_provider_representation?(op) ->
        translate_lines_to_bytes(op)

      has_canonical_representation?(op) ->
        # Provider already produced canonical bytes — pass through unchanged.
        {:ok, op}

      true ->
        # Neither provider-private nor canonical representation present.
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_post_image_representation}}
    end
  end

  defp translate_operation_to_canonical(_),
    do: {:error, %{code: :E_MALFORMED_OUTPUT, reason: :operation_not_object}}

  defp has_provider_representation?(op) do
    Map.has_key?(op, "after_image_lines") or Map.has_key?(op, :after_image_lines)
  end

  defp has_canonical_representation?(op) do
    Map.has_key?(op, "after_image_bytes") or Map.has_key?(op, :after_image_bytes)
  end

  defp translate_lines_to_bytes(op) do
    case extract_lines_and_final_newline(op) do
      {:ok, lines, final_newline} ->
        content = Enum.join(lines, "\n")
        after_image_bytes = if final_newline, do: content <> "\n", else: content

        op
        |> drop_keys(["after_image_lines", "final_newline", :after_image_lines, :final_newline])
        |> Map.put("after_image_bytes", after_image_bytes)
        |> Map.put(:after_image_bytes, after_image_bytes)
        |> case do
          translated -> {:ok, translated}
        end

      {:error, _} = err ->
        err
    end
  end

  defp extract_lines_and_final_newline(op) do
    lines_raw =
      Map.get(op, "after_image_lines") || Map.get(op, :after_image_lines)

    cond do
      lines_raw == nil ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_after_image_lines}}

      is_list(lines_raw) and length(lines_raw) >= 1 ->
        lines =
          Enum.map(lines_raw, fn
            l when is_binary(l) -> l
            _ -> :invalid
          end)

        if Enum.any?(lines, &(&1 == :invalid)) do
          {:error, %{code: :E_MALFORMED_OUTPUT, reason: :after_image_lines_not_strings}}
        else
          final_newline =
            case Map.fetch(op, "final_newline") do
              {:ok, v} when is_boolean(v) -> v
              {:ok, _} -> true
              :error ->
                case Map.fetch(op, :final_newline) do
                  {:ok, v} when is_boolean(v) -> v
                  {:ok, _} -> true
                  :error -> true
                end
            end

          {:ok, lines, final_newline}
        end

      true ->
        {:error, %{code: :E_MALFORMED_OUTPUT, reason: :after_image_lines_not_array}}
    end
  end

  defp drop_keys(map, keys) do
    Enum.reduce(keys, map, fn k, acc ->
      case Map.pop(acc, k) do
        {_, rest} -> rest
      end
    end)
  end

  # Pre-approval content-validity gate: every operation's canonical
  # `after_image_bytes` must be parseable as Elixir. A model that emits
  # malformed bytes (e.g., a JSON-escaping bug producing literal `\n`
  # sequences) cannot produce a viable PatchProposal for an Elixir
  # target. This is candidate admissibility, not execution verification —
  # the existing registered verifier still runs post-apply.
  defp validate_envelope_post_images_parseable(envelope) do
    ops =
      Map.get(envelope, "operations") || Map.get(envelope, :operations) || []

    Enum.reduce_while(ops, :ok, fn op, :ok ->
      after_image_bytes =
        Map.get(op, "after_image_bytes") || Map.get(op, :after_image_bytes) || ""

      if elixir_parseable?(after_image_bytes) do
        {:cont, :ok}
      else
        {:halt,
         {:error,
          %{
            code: :E_PROVIDER_REPRESENTATION_INVALID,
            reason:
              "post-image is not parseable as Elixir; refusing to emit candidate for governed approval"
          }}}
      end
    end)
  end

  defp elixir_parseable?(bytes) when is_binary(bytes) do
    case Code.string_to_quoted(bytes) do
      {:ok, _ast} -> true
      {:error, _} -> false
    end
  end

  defp elixir_parseable?(_), do: false

  defp safe_json_decode(binary, reason) do
    case JSON.decode(binary) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, _} -> {:error, %{code: :E_MALFORMED_OUTPUT, reason: reason}}
    end
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
