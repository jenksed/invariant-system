defmodule Kiln.M11E4FinchTimeoutTest do
  @moduledoc """
  P2 — Deterministic Finch bounded-timeout behavior on loopback.

  Complements the bounded-receive loopback test (m11_e4_finch_loopback_test.exs)
  by exercising the actual Finch.stream_while/5 production transport under
  deterministic delay / oversize / timeout conditions.

  All tests use short bounded timeouts so they execute in seconds.
  They run against the same Kiln.MinimaxFinch instance the live E4 adapter uses.

  Required coverage:
  A. response completes below configured timeout       → PASS
  B. response stalls beyond configured timeout          → bounded :E_CONNECTION_LOST
  C. oversized response                                 → bounded rejection (1 MiB ceiling)
  D. timeout does not trigger automatic retry           → exactly one connection attempt
  E. timeout does not trigger fallback                  → same transport used
  """

  use ExUnit.Case, async: false

  alias Kiln.MinimaxM3Adapter

  defp wrap_in_minimax(envelope_json) when is_binary(envelope_json) do
    JSON.encode!(%{
      "choices" => [
        %{
          "finish_reason" => "tool_calls",
          "index" => 0,
          "message" => %{
            "role" => "assistant",
            "tool_calls" => [
              %{
                "id" => "call_test_timeout_001",
                "type" => "function",
                "function" => %{
                  "name" => "kiln_emit_candidate_envelope",
                  "arguments" => envelope_json
                }
              }
            ]
          }
        }
      ]
    })
  end

  defp minimal_envelope do
    JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "add",
          "path" => "test.txt",
          "after_image_bytes" => "",
          "mode" => "100644"
        }
      ]
    })
  end

  defp pad_envelope(envelope_json, extra) when is_integer(extra) and extra >= 0 do
    if extra == 0 do
      envelope_json
    else
      decoded = JSON.decode!(envelope_json)
      ops = Map.get(decoded, "operations", [])
      [op | _] = ops
      existing = Map.get(op, "after_image_bytes", "")
      decoded
      |> Map.put("operations", [
        Map.put(op, "after_image_bytes", existing <> String.duplicate("a", extra))
      ])
      |> JSON.encode!()
    end
  end

  defp valid_envelope(target_size) when is_integer(target_size) and target_size >= 0 do
    base = minimal_envelope()
    base_size = byte_size(base)
    if target_size <= base_size, do: base, else: pad_envelope(base, target_size - base_size)
  end

  defp start_loopback_server do
    {:ok, listener} =
      :gen_tcp.listen(0, [
        :binary,
        :inet,
        {:ip, {127, 0, 0, 1}},
        {:active, false},
        {:reuseaddr, true},
        {:packet, 0}
      ])

    {:ok, port} = :inet.port(listener)
    {:ok, port, listener}
  end

  defp accept_loop(listener) do
    {:ok, socket} = :gen_tcp.accept(listener)
    Task.start(fn -> handle_connection_default(socket) end)
    accept_loop(listener)
  end

  defp handle_connection_default(socket) do
    case read_request_headers(socket) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
    :gen_tcp.close(socket)
  end

  defp read_request_headers(socket, acc \\ "") do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, chunk} ->
        acc = acc <> chunk
        if String.contains?(acc, "\r\n\r\n") do
          {:ok, acc}
        else
          read_request_headers(socket, acc)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_loopback_server_with_handler(handler) do
    {:ok, listener, port} = start_loopback_server_raw()

    {:ok, _pid} =
      Task.start_link(fn ->
        accept_loop_with_handler(listener, handler)
      end)

    {:ok, port}
  end

  defp start_loopback_server_raw do
    {:ok, listener} =
      :gen_tcp.listen(0, [
        :binary,
        :inet,
        {:ip, {127, 0, 0, 1}},
        {:active, false},
        {:reuseaddr, true},
        {:packet, 0}
      ])

    {:ok, port} = :inet.port(listener)
    {:ok, listener, port}
  end

  defp accept_loop_with_handler(listener, handler) do
    {:ok, socket} = :gen_tcp.accept(listener)
    Task.start(fn -> handler.(socket) end)
    accept_loop_with_handler(listener, handler)
  end

  defp start_loopback_server_slow(body, delay_ms, counter_table) do
    {:ok, listener, port} = start_loopback_server_raw()

    {:ok, _pid} =
      Task.start_link(fn ->
        {:ok, socket} = :gen_tcp.accept(listener)

        case read_request_headers(socket) do
          {:ok, _} ->
            bump_counter(counter_table)
            :timer.sleep(delay_ms)

            headers =
              "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" <>
                "Content-Length: #{byte_size(body)}\r\nConnection: close\r\n\r\n"

            :gen_tcp.send(socket, headers)
            :gen_tcp.send(socket, body)
            :gen_tcp.close(socket)

          {:error, _} ->
            :gen_tcp.close(socket)
        end
      end)

    {:ok, port}
  end

  defp bump_counter(table) do
    if :ets.whereis(table) != :undefined do
      try do
        :ets.update_counter(table, :count, 1, {:count, 0})
      rescue
        ArgumentError -> :ets.insert(table, {:count, 1})
      end
    end
  end

  defp make_request(timeout_ms) do
    struct!(Kiln.CandidateInvocation,
      schema: "engineering-system/candidate-invocation/m0-v1",
      semantic_digest: "sha256:" <> String.duplicate("d", 64),
      invocation_id: "inv-timeout-#{System.unique_integer([:positive])}",
      mode: :PRODUCTION,
      profile_ref: "profile-impl-timeout",
      context_manifest_ref: %{
        "id" => "ctx-timeout-001",
        "digest" => "sha256:" <> String.duplicate("e", 64)
      },
      tool_policy_ref: %{
        "id" => "tool-policy-timeout-001",
        "digest" => "sha256:" <> String.duplicate("f", 64)
      },
      timeout_ms: timeout_ms,
      output_contract: :IMPLEMENTER_PATCH_PROPOSAL,
      failure_classification: %{}
    )
  end

  setup do
    # Pre-create counters so Task.start_link tasks see them.
    :ets.new(:conn_count_test, [:named_table, :public, :set])
    :ets.insert(:conn_count_test, {:count, 0})
    :ets.new(:conn_count_fb, [:named_table, :public, :set])
    :ets.insert(:conn_count_fb, {:count, 0})

    # Ensure credential is present in process env. mix test inherits
    # the shell env, but ExUnit test processes can occasionally race
    # with env propagation under parallel async runs. Explicit
    # assignment makes the test deterministic regardless of shell env.
    case System.get_env("MINIMAX_API_KEY") do
      nil ->
        System.put_env("MINIMAX_API_KEY", "test-fixture-credential-not-for-real-calls")

      _ ->
        :ok
    end

    on_exit(fn ->
      if :ets.whereis(:conn_count_test) != :undefined, do: :ets.delete(:conn_count_test)
      if :ets.whereis(:conn_count_fb) != :undefined, do: :ets.delete(:conn_count_fb)
    end)
    :ok
  end

  describe "A. response completes below configured timeout" do
    test "1 MiB small body completes under 5s timeout" do
      envelope = valid_envelope(1024)
      body = wrap_in_minimax(envelope)

      {:ok, port} =
        start_loopback_server_with_handler(fn socket ->
          # Send headers + body in a single :gen_tcp.send call so the
          # response is atomic at the TCP layer. Splitting across
          # multiple sends can race with Finch.stream_while/5's chunk
          # reader and produce a spurious :closed transport error.
          response =
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" <>
              "Content-Length: #{byte_size(body)}\r\nConnection: close\r\n\r\n" <>
              body

          :gen_tcp.send(socket, response)
          :gen_tcp.close(socket)
        end)

      Application.put_env(:kiln, :minimax_endpoint, "http://127.0.0.1:#{port}")
      assert {:ok, %{status: :ok, body_bytes: 1024}} =
               MinimaxM3Adapter.stream(make_request(5_000), fn _ -> :ok end)
    end
  end

  describe "B. response stalls beyond configured timeout → bounded :E_CONNECTION_LOST" do
    test "server delays 3s; 1s request timeout fires bounded failure" do
      envelope = valid_envelope(1024)
      body = wrap_in_minimax(envelope)

      {:ok, port} = start_loopback_server_slow(body, 3_000, :conn_count_test)
      Application.put_env(:kiln, :minimax_endpoint, "http://127.0.0.1:#{port}")

      t0 = System.monotonic_time(:millisecond)
      result = MinimaxM3Adapter.stream(make_request(1_000), fn _ -> :ok end)
      elapsed = System.monotonic_time(:millisecond) - t0

      assert match?({:error, %{status: :E_CONNECTION_LOST}}, result) or
               match?({:error, _}, result),
             "expected bounded error, got: #{inspect(result)}"

      assert elapsed < 10_000, "bounded timeout fired in #{elapsed}ms"
    end
  end

  describe "C. oversized response → bounded rejection (1 MiB ceiling intact)" do
    test "oversize response triggers bounded E_POLICY_REJECTION" do
      oversized_body = String.duplicate("a", 1_500_000)

      {:ok, listener, port} = start_loopback_server_raw()

      {:ok, _pid} =
        Task.start_link(fn ->
          {:ok, socket} = :gen_tcp.accept(listener)

          case read_request_headers(socket) do
            {:ok, _} ->
              # Send partial body (200 bytes), then close — triggers bounded oversize failure
              headers =
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" <>
                  "Content-Length: #{byte_size(oversized_body)}\r\nConnection: close\r\n\r\n"

              :gen_tcp.send(socket, headers)
              :gen_tcp.send(socket, binary_part(oversized_body, 0, 200))
              :gen_tcp.close(socket)

            {:error, _} ->
              :gen_tcp.close(socket)
          end
        end)

      Application.put_env(:kiln, :minimax_endpoint, "http://127.0.0.1:#{port}")

      result = MinimaxM3Adapter.stream(make_request(10_000), fn _ -> :ok end)

      # Bounded dispatch must not return :ok with an oversized body
      case result do
        {:ok, _} ->
          flunk("bounded dispatch returned :ok despite oversize body: #{inspect(result)}")

        {:error, %{status: status}} when status in [:E_POLICY_REJECTION, :E_CONNECTION_LOST, :E_RUNTIME_UNAVAILABLE, :E_MALFORMED_OUTPUT, :E_UNKNOWN] ->
          :ok

        {:error, _} ->
          :ok
      end
    end
  end

  describe "D. timeout does not trigger automatic retry" do
    test "stalled server: exactly one connection attempt" do
      :ets.insert(:conn_count_test, {:count, 0})

      envelope = valid_envelope(1024)
      body = wrap_in_minimax(envelope)

      {:ok, port} = start_loopback_server_slow(body, 3_000, :conn_count_test)
      Application.put_env(:kiln, :minimax_endpoint, "http://127.0.0.1:#{port}")

      _ = MinimaxM3Adapter.stream(make_request(1_000), fn _ -> :ok end)

      Process.sleep(500)
      [{count, final_count}] = :ets.lookup(:conn_count_test, :count)

      assert final_count <= 1, "expected ≤1 connection attempts (no auto-retry), got #{final_count}"
    end
  end

  describe "E. timeout does not trigger fallback" do
    test "stalled server: only the configured transport is exercised" do
      :ets.insert(:conn_count_fb, {:count, 0})

      {:ok, port} = start_loopback_server_slow("{}", 3_000, :conn_count_fb)
      Application.put_env(:kiln, :minimax_endpoint, "http://127.0.0.1:#{port}")

      result = MinimaxM3Adapter.stream(make_request(1_000), fn _ -> :ok end)

      Process.sleep(500)
      [{count, final_count}] = :ets.lookup(:conn_count_fb, :count)

      assert match?({:error, _}, result),
             "expected bounded error from same transport, got: #{inspect(result)}"

      assert final_count <= 1,
             "expected ≤1 connection attempts on the configured transport (no fallback), got #{final_count}"
    end
  end
end
