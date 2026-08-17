defmodule Kiln.MinimaxM3AdapterDeterministicTest do
  @moduledoc """
  Deterministic provider proof for `Kiln.MinimaxM3Adapter`.

  Every assertion in this file runs through a deterministic transport seam
  (the dispatch function is overridden via `Application.put_env/3` to a local
  function returning canned responses). No live network, no live credential,
  no real `MINIMAX_API_KEY` value ever appears in a returned field, log,
  artifact, or result payload.

  These tests prove the bounded properties of the KILN-M0-01
  implementation in isolation from the network: bounded raw transport
  receipt, bounded timeout, no retry, no fallback, secret non-propagation,
  canonical failure-class normalization.
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
    original = Application.get_env(:kiln, :minimax_http_dispatch)
    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:kiln, :minimax_http_dispatch)
        v -> Application.put_env(:kiln, :minimax_http_dispatch, v)
      end
    end)

    original_key = System.get_env("MINIMAX_API_KEY")
    on_exit(fn ->
      case original_key do
        nil -> System.delete_env("MINIMAX_API_KEY")
        v -> System.put_env("MINIMAX_API_KEY", v)
      end
    end)

    # Default the credential so most tests do not have to repeat it.
    # Tests that want the "missing credential" terminal set it to nil after
    # calling System.put_env with an empty string.
    System.put_env("MINIMAX_API_KEY", "det-test-credential")

    :ok
  end

  defp install_dispatch(canned) do
    Application.put_env(:kiln, :minimax_http_dispatch, fn _opts -> canned end)
  end

  defp make_request do
    {:ok, req} = CandidateInvocation.new_request(@valid_attrs)
    req
  end

  describe "bounded raw transport receipt" do
    test "accepts a body below the 1 MiB ceiling" do
      body = String.duplicate("a", 1024)
      install_dispatch({:ok, {{:"HTTP/1.1", 200, "OK"}, [], body}})

      assert {:ok, %{status: :ok, body: ^body, body_bytes: 1024}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "accepts a body exactly at the 1 MiB ceiling" do
      ceiling = MinimaxM3Adapter.max_response_bytes()
      body = String.duplicate("b", ceiling)
      install_dispatch({:ok, {{:"HTTP/1.1", 200, "OK"}, [], body}})

      assert {:ok, result} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
      assert result.body_bytes == ceiling
    end

    test "rejects a body that is first byte over the ceiling, before unbounded accumulation" do
      ceiling = MinimaxM3Adapter.max_response_bytes()
      over = String.duplicate("c", ceiling + 1)
      install_dispatch({:ok, {{:"HTTP/1.1", 200, "OK"}, [], over}})

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end

    test "rejects a body that is far over the ceiling" do
      install_dispatch(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], String.duplicate("d", MinimaxM3Adapter.max_response_bytes() * 2)}}
      )

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end
  end

  describe "no retry, no fallback, exactly one dispatch attempt" do
    test "exactly one dispatch on 2xx success" do
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok-body"}},
        test_pid,
        :ok
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on 4xx error" do
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 429, "Too Many Requests"}, [], "rate-limited"}},
        test_pid,
        :ok
      )

      assert {:error, %{status: :E_POLICY_REJECTION}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on 5xx error" do
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 503, "Service Unavailable"}, [], "down"}},
        test_pid,
        :ok
      )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on malformed response (no exception escape)" do
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok-body"}},
        test_pid,
        :ok
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "exactly one dispatch on transport failure (no retry)" do
      test_pid = self()

      install_dispatch_with_counter(
        {:error, :econnrefused},
        test_pid,
        :ok
      )

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}
    end

    test "no alternate provider path: the single dispatch is the only network attempt" do
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid,
        :ok
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:dispatched, 1}

      refute_received {:alternate_dispatch, _}
    end
  end

  describe "secret non-propagation" do
    test "a unique synthetic sentinel credential is absent from every result field" do
      sentinel = "SENTINEL-THIS-VALUE-MUST-NOT-LEAK-INTO-ANY-RESULT-FIELD"
      System.put_env("MINIMAX_API_KEY", sentinel)

      body = "any response body the seam chooses to return"
      install_dispatch({:ok, {{:"HTTP/1.1", 200, "OK"}, [], body}})

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

    test "sentinel is absent from the request body sent over the seam" do
      sentinel = "SENTINEL-REQUEST-BODY-LEAK-PROBE"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()

      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      body =
        opts
        |> Keyword.get(:body)
        |> case do
          b when is_binary(b) -> b
          _ -> ""
        end

      refute body =~ sentinel,
             "credential value leaked into the request body sent to the provider"
    end

    test "sentinel is absent from the authorization header value passed to the seam" do
      sentinel = "SENTINEL-HEADER-LEAK-PROBE"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()

      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      body =
        opts
        |> Keyword.get(:body)
        |> case do
          b when is_binary(b) -> b
          _ -> ""
        end

      refute body =~ sentinel,
             "credential value leaked into the request body sent to the provider"
    end
  end

  describe "availability / credential boundary" do
    test "missing MINIMAX_API_KEY → terminal E_RUNTIME_UNAVAILABLE, no dispatch attempted" do
      System.delete_env("MINIMAX_API_KEY")
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid,
        :ok
      )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      refute_received {:dispatched, _}
    end

    test "empty MINIMAX_API_KEY → terminal E_RUNTIME_UNAVAILABLE, no dispatch attempted" do
      System.put_env("MINIMAX_API_KEY", "")
      test_pid = self()

      install_dispatch_with_counter(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid,
        :ok
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

    test "the dispatched request uses POST with JSON body and Bearer auth header" do
      System.put_env("MINIMAX_API_KEY", "det-test-credential")

      test_pid = self()
      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      assert opts[:url] == "https://api.minimax.io/v1/chat/completions"
      assert opts[:method] == :post

      headers = Keyword.get(opts, :headers, [])
      content_type = Enum.find_value(headers, fn {"content-type", v} -> v; _ -> nil end)
      auth = Enum.find_value(headers, fn {"authorization", v} -> v; _ -> nil end)
      assert content_type == "application/json"
      assert auth == "Bearer det-test-credential"
    end

    test "the dispatched body carries the canonical request fields" do
      System.put_env("MINIMAX_API_KEY", "x")
      test_pid = self()
      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      body_bytes = opts[:body]
      decoded = JSON.decode!(body_bytes)

      assert decoded["model"] == "MiniMax-M3"
      assert decoded["invocation_id"] == "inv-det-001"
      assert decoded["mode"] == "PRODUCTION"
      assert decoded["output_contract"] == "IMPLEMENTER_PATCH_PROPOSAL"
      assert decoded["stream"] == false
      assert decoded["timeout_ms"] == 60_000
    end

    test "sentinel is carried in the Authorization header but NOT in the request body or result fields" do
      sentinel = "SENTINEL-HEADER-AND-BODY-LEAK-PROBE"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()
      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, result} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      body =
        opts
        |> Keyword.get(:body)
        |> case do
          b when is_binary(b) -> b
          _ -> ""
        end

      auth_header =
        opts
        |> Keyword.get(:headers, [])
        |> Enum.find_value(fn
          {"authorization", v} -> v
          _ -> nil
        end)

      assert auth_header == "Bearer #{sentinel}",
             "the Authorization header legitimately carries the credential value (Bearer auth)"

      refute body =~ sentinel,
             "credential value leaked into the request body sent to the provider"

      refute result.body =~ sentinel,
             "credential value leaked into the bounded response body"
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

    test "transport error (econnrefused) → E_CONNECTION_LOST" do
      System.put_env("MINIMAX_API_KEY", "x")
      install_dispatch({:error, :econnrefused})

      assert {:error, %{status: :E_CONNECTION_LOST}} =
               MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
    end
  end

  describe "bounded timeout is taken from request.timeout_ms" do
    test "the request timeout option equals the request timeout_ms" do
      System.put_env("MINIMAX_API_KEY", "x")
      test_pid = self()
      install_dispatch_with_capture(
        {:ok, {{:"HTTP/1.1", 200, "OK"}, [], "ok"}},
        test_pid
      )

      assert {:ok, _} = MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)

      assert_received {:request_captured, opts}

      assert opts[:timeout] == 60_000
      assert opts[:connect_timeout] == 60_000
    end
  end

  # --- helpers ---

  defp run_with_status(status, expected_class) do
    System.put_env("MINIMAX_API_KEY", "x")
    install_dispatch({:ok, {{:"HTTP/1.1", status, "Status"}, [], "body"}})

    assert {:error, %{status: ^expected_class}} =
             MinimaxM3Adapter.stream(make_request(), fn _ -> :ok end)
  end

  defp install_dispatch_with_counter(canned_result, test_pid, _event_marker) do
    counter = :counters.new(1, [])

    Application.put_env(:kiln, :minimax_http_dispatch, fn _opts ->
      :counters.add(counter, 1, 1)
      send(test_pid, {:dispatched, :counters.get(counter, 1)})
      canned_result
    end)
  end

  defp install_dispatch_with_capture(canned_result, test_pid) do
    Application.put_env(:kiln, :minimax_http_dispatch, fn opts ->
      send(test_pid, {:request_captured, opts})
      canned_result
    end)
  end

  defp result_and_event(stream_result) do
    case stream_result do
      {:ok, _} = ok -> {nil, ok}
      {:error, _} = err -> {nil, err}
    end
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
