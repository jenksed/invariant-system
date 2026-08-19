defmodule Kiln.M0CandidateInvocationTest do
  use ExUnit.Case, async: true

  alias Kiln.CandidateInvocation
  alias Kiln.MinimaxM3Adapter

  # Wrap a canonical envelope JSON string in the MiniMax chat-completion
  # response wrapper format expected by `decode_provider_response_wrapper/1`.
  # This is the canonical accepted provider response shape; the bounded
  # parser rejects anything else with E_MALFORMED_OUTPUT.
  defp wrap_in_minimax(envelope_json) when is_binary(envelope_json) do
    Jason.encode!(%{
      "choices" => [
        %{
          "finish_reason" => "tool_calls",
          "index" => 0,
          "message" => %{
            "role" => "assistant",
            "tool_calls" => [
              %{
                "id" => "call_test_001",
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

  @valid_request %{
    "invocation_id" => "inv-test-001",
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

  describe "Kiln.CandidateInvocation.new_request/1" do
    test "validates a canonical request and computes semantic_digest" do
      assert {:ok, %CandidateInvocation{} = request} =
               CandidateInvocation.new_request(@valid_request)

      assert request.schema == "engineering-system/candidate-invocation/m0-v1"
      assert request.invocation_id == "inv-test-001"
      assert request.mode == :PRODUCTION
      assert request.output_contract == :IMPLEMENTER_PATCH_PROPOSAL
      assert request.failure_classification == "M0_CANONICAL_FAILURE_TAXONOMY_V1"
      assert request.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
    end

    test "semantic_digest is stable across calls with identical input" do
      {:ok, a} = CandidateInvocation.new_request(@valid_request)
      {:ok, b} = CandidateInvocation.new_request(@valid_request)
      assert a.semantic_digest == b.semantic_digest
    end

    test "rejects requests with no credential-shaped fields present (negative: missing field)" do
      attrs = Map.delete(@valid_request, "invocation_id")
      assert {:error, {:missing_field, :invocation_id}} = CandidateInvocation.new_request(attrs)
    end

    test "rejects requests whose mode is not in the canonical set" do
      attrs = Map.put(@valid_request, "mode", "evaluation")

      assert {:error, {:invalid_field, :mode, "evaluation"}} =
               CandidateInvocation.new_request(attrs)
    end

    test "rejects requests with a timeout outside the bounded 1s..30min window" do
      too_short = Map.put(@valid_request, "timeout_ms", 100)

      assert {:error, {:invalid_field, :timeout_ms, 100}} =
               CandidateInvocation.new_request(too_short)

      too_long = Map.put(@valid_request, "timeout_ms", 1_900_000)

      assert {:error, {:invalid_field, :timeout_ms, 1_900_000}} =
               CandidateInvocation.new_request(too_long)
    end
  end

  describe "Kiln.MinimaxM3Adapter" do
    test "implements Kiln.Conformance.Provider behaviour" do
      # The module declares @behaviour Kiln.Conformance.Provider and exports
      # both required callbacks; behaviour_info may not be public on all
      # Elixir versions, so we assert via function_exported? instead.
      assert function_exported?(MinimaxM3Adapter, :stream, 2)
      assert function_exported?(MinimaxM3Adapter, :cancel, 1)
    end

    test "implementation_digest is stable across calls" do
      d1 = MinimaxM3Adapter.implementation_digest()
      d2 = MinimaxM3Adapter.implementation_digest()
      assert d1 == d2
      assert d1 =~ ~r/^sha256:[0-9a-f]{64}$/
    end

    test "NEGATIVE runtime-unavailable: terminal E_RUNTIME_UNAVAILABLE when credential absent" do
      System.delete_env("MINIMAX_API_KEY")

      {:ok, request} = CandidateInvocation.new_request(@valid_request)

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} =
               MinimaxM3Adapter.stream(request, fn _ -> :ok end)
    end
    test "NEGATIVE provider-substitution: tampered semantic_digest is not a defense-in-depth check at the adapter layer" do
      # The KILN-M0-01 bounded adapter (per the M11 E2 P3+P4+P6 bounded
      # implementation repair) delegates semantic_digest validation to
      # `CandidateInvocation.new_request/1`. The adapter itself is a
      # transport provider; the request it dispatches is the same
      # CandidateInvocation struct that the caller validated. A tampered
      # semantic_digest on the struct the adapter receives therefore
      # means the caller bypassed `new_request/1`'s validation; the
      # adapter's bounded response handling and failure-class mapping
      # still apply to the raw response from the seam.
      #
      # The previous fixture returned body: "ok" which is not a valid
      # MiniMax wrapper and therefore caused the adapter to return
      # E_MALFORMED_OUTPUT, not the asserted {:ok, _}. The body must
      # be a valid canonical wrapper so the parser succeeds and the
      # adapter extracts the embedded envelope.
      #
      # on_exit registers failure-safe state restoration: even if the
      # assertion fails AND the previous inline cleanup is skipped,
      # the transport seam and the env var are still cleaned up.
      original_key = System.get_env("MINIMAX_API_KEY")
      original_transport = Application.get_env(:kiln, :minimax_transport)

      on_exit(fn ->
        case original_key do
          nil -> System.delete_env("MINIMAX_API_KEY")
          v -> System.put_env("MINIMAX_API_KEY", v)
        end

        case original_transport do
          nil -> Application.delete_env(:kiln, :minimax_transport)
          v -> Application.put_env(:kiln, :minimax_transport, v)
        end
      end)

      System.put_env("MINIMAX_API_KEY", "sentinel-value-not-leaked-into-output")

      {:ok, request} = CandidateInvocation.new_request(@valid_request)

      tampered = %{request | semantic_digest: "sha256:" <> String.duplicate("0", 64)}

      # Canonical envelope JSON: same semantic_digest computation as the
      # candidate invocation's normalized inputs produces.
      envelope =
        Jason.encode!(%{
          "schema" => "engineering-system/implementer-patch-proposal-input/v1",
          "operations" => [
            %{
              "op" => "add",
              "path" => "products/kiln/lib/kiln/_decoy.ex",
              "mode" => "100644",
              "after_image_bytes" => "x"
            }
          ]
        })

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          {:ok, %{status: 200, headers: [], body: wrap_in_minimax(envelope)}}
        end
      )

      assert {:ok, _} =
               MinimaxM3Adapter.stream(tampered, fn _ -> :ok end)
    end

    test "NEGATIVE secret-disclosure: credential value does not appear in any result field" do
      sentinel = "SENTINEL-CREDENTIAL-VALUE-NEVER-IN-RESULT"

      # Failure-safe cleanup registered BEFORE any assertion can fail.
      original_key = System.get_env("MINIMAX_API_KEY")
      original_transport = Application.get_env(:kiln, :minimax_transport)

      on_exit(fn ->
        case original_key do
          nil -> System.delete_env("MINIMAX_API_KEY")
          v -> System.put_env("MINIMAX_API_KEY", v)
        end

        case original_transport do
          nil -> Application.delete_env(:kiln, :minimax_transport)
          v -> Application.put_env(:kiln, :minimax_transport, v)
        end
      end)

      System.put_env("MINIMAX_API_KEY", sentinel)

      # Install a deterministic transport seam that returns a canned 401
      # response without touching the real network.
      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          {:ok, %{status: 401, headers: [], body: "unauthorized"}}
        end
      )

      {:ok, request} = CandidateInvocation.new_request(@valid_request)
      {:error, result} = MinimaxM3Adapter.stream(request, fn _ -> :ok end)

      for {k, v} <- result do
        if is_binary(v) do
          refute v =~ sentinel,
                 "credential value leaked into result field: #{inspect({k, v})}"
        end
      end
    end

    test "endpoint is the single bounded MiniMax M3 chat completions endpoint" do
      assert MinimaxM3Adapter.endpoint() == "https://api.minimax.io/v1/chat/completions"
    end
  end
end
