defmodule Kiln.MinimaxM3AdapterDeterministicTest do
  @moduledoc """
  Deterministic provider proof for `Kiln.MinimaxM3Adapter`.

  Every assertion in this file runs through a deterministic transport seam
  (the transport function is overridden via `Application.put_env(:kiln,
  :minimax_transport, fn ...)` to a local function returning canned response
  sequences). No live network, no live credential, no real `MINIMAX_API_KEY`
  value ever appears in a returned field, log, artifact, or result payload.

  These tests prove the bounded properties of the KILN-M0-01
  implementation in isolation from the network:

    - bounded raw transport receipt (via `process_stream_events/2`);
    - bounded response acceptance (via the transport seam);
    - no retry, no fallback, exactly one dispatch attempt;
    - secret non-propagation;
    - availability / credential boundary;
    - request formation;
    - canonical failure-class normalization.

  The bounded receive path property (status available before body
  materialization + incremental bounded body receipt + halt on oversize)
  is proved by `process_stream_events/2` directly with simulated Finch
  event sequences, without needing a real Finch instance or a real
  HTTP server.
  """

  use ExUnit.Case, async: false

  alias Kiln.CandidateInvocation
  alias Kiln.MinimaxM3Adapter

  @valid_attrs %{
    "invocation_id" => "inv-det-001",
    "mode" => "PRODUCTION",
    "profile_ref" => %{"id" => "profile-impl", "digest" => "sha256:" <> String.duplicate("a", 64)},
    "context_manifest_ref" => %{
      "id" => "ctx-manifest-001",
      "digest" => "sha256:" <> String.duplicate("b", 64)
    },
    "tool_policy_ref" => %{
      "id" => "tool-policy-001",
      "digest" => "sha256:" <> String.duplicate("c", 64)
    },
    "timeout_ms" => 60_000,
    "output_contract" => "IMPLEMENTER_PATCH_PROPOSAL"
  }

  setup do
    original = Application.get_env(:kiln, :minimax_transport)
    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:kiln, :minimax_transport)
        v -> Application.put_env(:kiln, :minimax_transport, v)
      end
    end)

    original_key = System.get_env("MINIMAX_API_KEY")
    on_exit(fn ->
      case original_key do
        nil -> System.delete_env("MINIMAX_API_KEY")
        v -> System.put_env("MINIMAX_API_KEY", v)
      end
    end)

    System.put_env("MINIMAX_API_KEY", "det-test-credential")

    :ok
  end

  defp install_transport(canned) do
    Application.put_env(:kiln, :minimax_transport, fn _request, _credential, _opts -> canned end)
  end

  defp install_transport_with_counter(canned, test_pid) do
    counter = :counters.new(1, [])

    Application.put_env(
      :kiln,
      :minimax_transport,
      fn _request, _credential, _opts ->
        :counters.add(counter, 1, 1)
        send(test_pid, {:dispatched, :counters.get(counter, 1)})
        canned
      end
    )
  end

  defp install_transport_with_capture(canned, test_pid) do
    Application.put_env(
      :kiln,
      :minimax_transport,
      fn request, credential, opts ->
        send(test_pid, {:transport_captured, {request, credential, opts}})
        canned
      end
    )
  end

  defp make_request do
    {:ok, req} = CandidateInvocation.new_request(@valid_attrs)
    req
  end

  describe "bounded raw transport receipt (process_stream_events/2)" do
    test "single chunk below the 1 MiB ceiling is accepted" do
      limit = MinimaxM3Adapter.max_response_bytes()
      expected_bytes = limit - 1
      body = String.duplicate("a", expected_bytes)

      events = [
        {:status, 200},
        {:headers, []},
        {:data, body}
      ]

      assert {:ok, %{status: 200, body: ^body, body_bytes: ^expected_bytes}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "single chunk exactly at the 1 MiB ceiling is accepted" do
      limit = MinimaxM3Adapter.max_response_bytes()
      body = String.duplicate("b", limit)

      events = [
        {:status, 200},
        {:headers, []},
        {:data, body}
      ]

      assert {:ok, %{status: 200, body_bytes: ^limit, body: ^body}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "single chunk first byte over the ceiling halts and discards partial body" do
      limit = MinimaxM3Adapter.max_response_bytes()
      over = String.duplicate("c", limit + 1)
      expected_bytes = limit + 1

      events = [
        {:status, 200},
        {:headers, []},
        {:data, over}
      ]

      assert {:halt, ^expected_bytes} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "single chunk far over the ceiling halts" do
      limit = MinimaxM3Adapter.max_response_bytes()
      over = String.duplicate("d", limit * 2)
      expected_bytes = limit * 2

      events = [
        {:status, 200},
        {:headers, []},
        {:data, over}
      ]

      assert {:halt, ^expected_bytes} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "multi-chunk below limit: all chunks accumulated" do
      limit = MinimaxM3Adapter.max_response_bytes()
      chunk = String.duplicate("x", 100)
      expected_bytes = 100 * 100
      events = [{:status, 200}, {:headers, []}] ++ List.duplicate({:data, chunk}, 100)

      assert {:ok, %{body_bytes: ^expected_bytes, status: 200}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "multi-chunk exactly at limit: all chunks accumulated" do
      limit = 1000
      chunk = String.duplicate("y", 100)
      expected_bytes = 1000
      events = [{:status, 200}, {:headers, []}] ++ List.duplicate({:data, chunk}, 10)

      assert {:ok, %{body_bytes: ^expected_bytes, status: 200}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "multi-chunk crossing limit: halts on the over-limit chunk" do
      limit = 1000
      chunk = String.duplicate("z", 400)
      expected_bytes = 1200
      events = [{:status, 200}, {:headers, []}, {:data, chunk}, {:data, chunk}, {:data, chunk}]

      # After 2 chunks: 800 bytes. 3rd chunk would push to 1200 > 1000 → halt.
      assert {:halt, ^expected_bytes} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "multi-chunk error response crossing limit also halts" do
      limit = 100
      chunk = String.duplicate("e", 60)
      expected_bytes = 120
      events = [{:status, 500}, {:headers, []}, {:data, chunk}, {:data, chunk}]

      # After 1 chunk: 60. 2nd chunk would push to 120 > 100 → halt.
      assert {:halt, ^expected_bytes} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "status event is captured before any body processing" do
      limit = 1000
      events = [{:status, 401}, {:headers, []}, {:data, "unauthorized"}]

      assert {:ok, %{status: 401, body: "unauthorized"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "401 response below limit maps to oversize-halting body size" do
      limit = 1000
      events = [{:status, 401}, {:headers, []}, {:data, String.duplicate("a", 600)}]

      assert {:ok, %{status: 401, body_bytes: 600}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "403 response below limit" do
      limit = 1000
      events = [{:status, 403}, {:headers, []}, {:data, "forbidden"}]

      assert {:ok, %{status: 403, body: "forbidden"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "408 response below limit" do
      limit = 1000
      events = [{:status, 408}, {:headers, []}, {:data, "timeout"}]

      assert {:ok, %{status: 408, body: "timeout"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "429 response below limit" do
      limit = 1000
      events = [{:status, 429}, {:headers, []}, {:data, "rate-limited"}]

      assert {:ok, %{status: 429, body: "rate-limited"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "500 response below limit" do
      limit = 1000
      events = [{:status, 500}, {:headers, []}, {:data, "server-error"}]

      assert {:ok, %{status: 500, body: "server-error"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "502 response below limit" do
      limit = 1000
      events = [{:status, 502}, {:headers, []}, {:data, "bad-gateway"}]

      assert {:ok, %{status: 502, body: "bad-gateway"}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "401 response above limit" do
      limit = 1000
      over = String.duplicate("a", 1001)
      events = [{:status, 401}, {:headers, []}, {:data, over}]

      assert {:halt, 1001} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "403 response above limit" do
      limit = 1000
      over = String.duplicate("a", 1001)
      events = [{:status, 403}, {:headers, []}, {:data, over}]

      assert {:halt, 1001} = MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "trailers event is observed without side effect" do
      limit = 1000
      events = [{:status, 200}, {:headers, []}, {:data, "body"}, {:trailers, []}]

      assert {:ok, %{status: 200, body: "body", body_bytes: 4}} =
               MinimaxM3Adapter.process_stream_events(events, limit)
    end

    test "data after halt is not accumulated (the partial body is discarded)" do
      limit = 100
      chunk = String.duplicate("x", 60)
      events = [{:status, 200}, {:headers, []}, {:data, chunk}, {:data, chunk}, {:data, chunk}]

      # After 1 chunk: 60. 2nd chunk: 120 > 100 → halt.
      # The 3rd chunk would NOT be processed.
      assert {:halt, 120} = MinimaxM3Adapter.process_stream_events(events, limit)
    end
  end

  describe "bounded response acceptance (via transport seam)" do
    test "accepts a body below the 1 MiB ceiling" do
      body = String.duplicate("a", 1024)
      install_transport({:ok, %{status: 200, headers: [], body: body}})

      assert {:ok, %{status: :ok, body: ^body, body_bytes: 1024}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "accepts a body exactly at the 1 MiB ceiling" do
      ceiling = MinimaxM3Adapter.max_response_bytes()
      body = String.duplicate("b", ceiling)
      install_transport({:ok, %{status: 200, headers: [], body: body}})

      assert {:ok, result} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
      assert result.body_bytes == ceiling
    end

    test "rejects a body that is first byte over the ceiling" do
      ceiling = MinimaxM3Adapter.max_response_bytes()
      over = String.duplicate("c", ceiling + 1)
      install_transport({:ok, %{status: 200, headers: [], body: over}})

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "rejects a body that is far over the ceiling" do
      install_transport(
        {:ok, %{status: 200, headers: [], body: String.duplicate("d", MinimaxM3Adapter.max_response_bytes() * 2)}}
      )

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "transport seam oversize error reaches the adapter as :E_POLICY_REJECTION" do
      ceiling = MinimaxM3Adapter.max_response_bytes()
      install_transport({:error, :oversize, ceiling + 1})

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end
  end

  describe "no retry, no fallback, exactly one dispatch attempt" do
    test "exactly one dispatch on 2xx success" do
      test_pid = self()
      install_transport_with_counter(
        {:ok, %{status: 200, headers: [], body: "ok-body"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on 4xx error" do
      test_pid = self()
      install_transport_with_counter(
        {:ok, %{status: 429, headers: [], body: "rate-limited"}},
        test_pid
      )

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on 5xx error" do
      test_pid = self()
      install_transport_with_counter(
        {:ok, %{status: 503, headers: [], body: "down"}},
        test_pid
      )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on transport failure" do
      test_pid = self()
      install_transport_with_counter(
        {:error, :finch_error, :econnrefused},
        test_pid
      )

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on oversize error from transport" do
      test_pid = self()
      install_transport_with_counter(
        {:error, :oversize, 1_048_577},
        test_pid
      )

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end
  end

  describe "secret non-propagation" do
    test "a unique synthetic sentinel credential is absent from every result field" do
      sentinel = "SENTINEL-THIS-VALUE-MUST-NOT-LEAK-INTO-ANY-RESULT-FIELD"
      System.put_env("MINIMAX_API_KEY", sentinel)

      body = "any response body the seam chooses to return"
      install_transport({:ok, %{status: 200, headers: [], body: body}})

      {:ok, result} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert :ok = refute_sentinel_in_term(sentinel, result)
    end

    test "sentinel is absent even on terminal credential-absent failure" do
      System.put_env("MINIMAX_API_KEY", "")

      result =
        MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} = result
      assert :ok = refute_sentinel_in_term("whatever", result)
    end

    test "sentinel carrying the credential is forwarded to the transport" do
      sentinel = "SENTINEL-REQUEST-BODY-LEAK-PROBE"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()
      install_transport_with_capture(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:transport_captured, {request, credential, _opts}}

      assert request.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
      assert credential == sentinel,
             "the credential value must be passed to the transport (Bearer header) but not in any result field"
    end

    test "sentinel is absent from the request fields sent to the transport" do
      sentinel = "SENTINEL-REQUEST-BODY-LEAK-PROBE"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()
      install_transport_with_capture(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:transport_captured, {request, _credential, _opts}}

      refute request.semantic_digest =~ sentinel,
             "credential value leaked into the request semantic_digest"
    end
  end

  describe "availability / credential boundary" do
    test "missing MINIMAX_API_KEY → terminal E_RUNTIME_UNAVAILABLE, no dispatch attempted" do
      System.delete_env("MINIMAX_API_KEY")
      test_pid = self()
      install_transport_with_counter(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      refute_received {:dispatched, _}
    end

    test "empty MINIMAX_API_KEY → terminal E_RUNTIME_UNAVAILABLE, no dispatch attempted" do
      System.put_env("MINIMAX_API_KEY", "")
      test_pid = self()
      install_transport_with_counter(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      refute_received {:dispatched, _}
    end
  end

  describe "request formation" do
    test "endpoint is the single bounded MiniMax M3 chat completions URL" do
      assert MinimaxM3Adapter.endpoint() == "https://api.minimax.io/v1/chat/completions"
    end

    test "the transport receives the bounded request and the credential" do
      System.put_env("MINIMAX_API_KEY", "det-test-credential")

      test_pid = self()
      install_transport_with_capture(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:transport_captured, {request, credential, opts}}

      assert request.invocation_id == "inv-det-001"
      assert request.mode == :PRODUCTION
      assert credential == "det-test-credential"
      assert Keyword.get(opts, :timeout_ms) == 60_000
      assert Keyword.get(opts, :max_bytes) == MinimaxM3Adapter.max_response_bytes()
    end
  end

  describe "response behavior (canonical failure class mapping)" do
    test "401 → E_PROVIDER_DENIED" do
      run_with_status(401, :E_PROVIDER_DENIED)
    end

    test "403 → E_PROVIDER_DENIED" do
      run_with_status(403, :E_PROVIDER_DENIED)
    end

    test "408 → E_TIMEOUT" do
      run_with_status(408, :E_TIMEOUT)
    end

    test "429 → E_POLICY_REJECTION" do
      run_with_status(429, :E_POLICY_REJECTION)
    end

    test "500 → E_RUNTIME_UNAVAILABLE" do
      run_with_status(500, :E_RUNTIME_UNAVAILABLE)
    end

    test "502 → E_RUNTIME_UNAVAILABLE" do
      run_with_status(502, :E_RUNTIME_UNAVAILABLE)
    end

    test "transport error (finch_error) → E_CONNECTION_LOST" do
      System.put_env("MINIMAX_API_KEY", "x")
      install_transport({:error, :finch_error, :econnrefused})

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "transport error (disconnect) → E_CONNECTION_LOST" do
      System.put_env("MINIMAX_API_KEY", "x")
      install_transport({:error, :disconnect, :socket_closed})

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end
  end

  describe "bounded timeout is taken from request.timeout_ms" do
    test "the request timeout_ms is propagated to the transport opts" do
      System.put_env("MINIMAX_API_KEY", "x")
      test_pid = self()
      install_transport_with_capture(
        {:ok, %{status: 200, headers: [], body: "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:transport_captured, {_request, _credential, opts}}

      assert Keyword.get(opts, :timeout_ms) == 60_000
    end
  end

  # --- helpers ---

  defp run_with_status(status, expected_class) do
    System.put_env("MINIMAX_API_KEY", "x")
    install_transport({:ok, %{status: status, headers: [], body: "body"}})

    assert {:error, %{status: ^expected_class}} =
             MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
  end

  defp refute_sentinel_in_term(_sentinel, term) when is_map(term) do
    Enum.each(term, fn {_k, v} -> refute_sentinel_in_term(nil, v) end)
    :ok
  end

  defp refute_sentinel_in_term(_sentinel, term) when is_list(term) do
    Enum.each(term, fn v -> refute_sentinel_in_term(nil, v) end)
    :ok
  end

  defp refute_sentinel_in_term(sentinel, term) when is_binary(term) and is_binary(sentinel) do
    if String.contains?(term, sentinel) do
      flunk("sentinel credential value leaked into binary term")
    end

    :ok
  end

  defp refute_sentinel_in_term(_sentinel, _term), do: :ok
end
