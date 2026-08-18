defmodule Kiln.M11E4ProviderAuthorityTest do
  @moduledoc """
  P4 — Network authority enforcement proof.

  The provider-backed path MUST fail closed when execution authority
  is not explicitly granted. This test file proves the gate cannot
  be bypassed by provider selection + credential presence alone.

  Required property (P4):
    real-provider selected + credential present + no authority
    → NO transport invocation

  And:
    real-provider selected + no credential + authority
    → terminal unavailable / accepted missing-credential behavior

  And:
    real-provider selected + synthetic credential + explicit test authority
    → deterministic transport may execute (positive control)

  The default production values are:
    allowed_capabilities: []
    denied_capabilities:  ["provider.network"]

  These defaults result in a `:denied` decision, making live network
  execution impossible without explicit owner authorization.
  """

  use ExUnit.Case, async: false

  alias Kiln.Authority
  alias Kiln.MinimaxM3Adapter
  alias Kiln.Worker

  defp valid_envelope do
    %{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "add",
          "path" => "products/kiln/lib/kiln/operation_lifecycle.ex",
          "mode" => "100644",
          "after_image_bytes" => "defmodule Kiln.OperationLifecycle do\nend\n"
        }
      ]
    }
  end

  defp valid_envelope_bytes, do: Worker.canonical_envelope_bytes(valid_envelope())

  defp valid_request_attrs, do: valid_envelope()

  defp valid_assignment do
    %{
      "assignment_id" => "asg_authority_test",
      "role" => "IMPLEMENTER",
      "profile_ref" => %{"id" => "profile-impl", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64)
    }
  end

  defp valid_eligibility do
    %{
      "eligibility" => "QUALIFIED",
      "role" => "IMPLEMENTER",
      "profile_ref" => %{"id" => "profile-impl", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "derived_at" => "2026-08-16T00:00:00Z",
      "valid_until" => "2026-08-23T00:00:00Z"
    }
  end

  defp valid_profile do
    %{
      "profile_id" => "profile-impl",
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64),
      "system_config" => %{"id" => "ctx-manifest-001", "digest" => "sha256:" <> String.duplicate("b", 64)},
      "tool_policy" => %{"id" => "tool-policy-001", "digest" => "sha256:" <> String.duplicate("c", 64)}
    }
  end

  setup do
    original_mode = Application.get_env(:kiln, :worker_provider_mode)
    original_transport = Application.get_env(:kiln, :minimax_transport)
    original_allowed = Application.get_env(:kiln, :provider_network_allowed_capabilities)
    original_denied = Application.get_env(:kiln, :provider_network_denied_capabilities)
    original_key = System.get_env("MINIMAX_API_KEY")

    on_exit(fn ->
      case original_mode do
        nil -> Application.delete_env(:kiln, :worker_provider_mode)
        v -> Application.put_env(:kiln, :worker_provider_mode, v)
      end

      case original_transport do
        nil -> Application.delete_env(:kiln, :minimax_transport)
        v -> Application.put_env(:kiln, :minimax_transport, v)
      end

      case original_allowed do
        nil -> Application.delete_env(:kiln, :provider_network_allowed_capabilities)
        v -> Application.put_env(:kiln, :provider_network_allowed_capabilities, v)
      end

      case original_denied do
        nil -> Application.delete_env(:kiln, :provider_network_denied_capabilities)
        v -> Application.put_env(:kiln, :provider_network_denied_capabilities, v)
      end

      case original_key do
        nil -> System.delete_env("MINIMAX_API_KEY")
        v -> System.put_env("MINIMAX_API_KEY", v)
      end
    end)

    :ok
  end

  describe "default production behavior — no authority" do
    test "real_provider + credential present + default authority → NO transport invocation (provider_network_authority_denied)" do
      # Production default: no capability grant, explicit deny.
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, [])
      Application.put_env(:kiln, :provider_network_denied_capabilities, ["provider.network"])

      # A counter-flagged transport seam — if the gate is correct, this
      # MUST NOT be invoked.
      test_pid = self()

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          send(test_pid, :transport_was_called)
          {:ok, %{status: 200, headers: [], body: valid_envelope_bytes()}}
        end
      )

      System.put_env("MINIMAX_API_KEY", "sentinel-credential")

      repository_root = Path.expand("../..", File.cwd!())

      result =
        Worker.propose(
          valid_assignment(),
          valid_eligibility(),
          valid_profile(),
          valid_request_attrs(),
          repository_root
        )

      # The gate must close with the canonical authority-denied result.
      assert {:error, {:provider_network_authority_denied, reason}} = result
      assert reason == :unsupported_capability

      # The transport MUST NOT have been invoked.
      refute_received :transport_was_called
    end

    test "default production values deny the provider.network capability in Authority.decide/1" do
      # The default production deny is checked at the Authority layer.
      Application.put_env(:kiln, :provider_network_allowed_capabilities, [])
      Application.put_env(:kiln, :provider_network_denied_capabilities, ["provider.network"])

      repository_root = Path.expand("../..", File.cwd!())

      # Construct an observation from the repository root.
      # Use the public observation registry; we just need a valid one.
      observation =
        %Kiln.RepositoryObservation{
          repository: repository_root,
          head_resolved: true,
          current_commit: "0123456789abcdef0123456789abcdef01234567",
          repository_state_digest: "sha256:" <> String.duplicate("0", 64),
          input_state_digest: "",
          observed_at: "2026-08-17T00:00:00Z"
        }

      decision =
        Authority.decide(
          work_id: "wok-test",
          run_id: "run-test",
          requested_capability: "provider.network",
          requested_scope: repository_root,
          observation: observation,
          base_commit: "0123456789abcdef0123456789abcdef01234567",
          decision_id: "dec_test",
          now: "2026-08-17T00:00:00Z"
        )

      assert {:ok, %Authority{result: :denied, reason_code: :unsupported_capability}} = decision
    end
  end

  describe "credential presence vs execution authority" do
    test "real_provider + no credential + authority → terminal unavailable (credential gate)" do
      # The credential gate runs BEFORE the authority gate.
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])
      Application.put_env(:kiln, :provider_network_denied_capabilities, [])

      test_pid = self()

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          send(test_pid, :transport_was_called)
          {:ok, %{status: 200, headers: [], body: valid_envelope_bytes()}}
        end
      )

      System.delete_env("MINIMAX_API_KEY")

      repository_root = Path.expand("../..", File.cwd!())

      result =
        Worker.propose(
          valid_assignment(),
          valid_eligibility(),
          valid_profile(),
          valid_request_attrs(),
          repository_root
        )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} = result
      refute_received :transport_was_called
    end

    test "real_provider + empty credential + authority → terminal unavailable" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])
      Application.put_env(:kiln, :provider_network_denied_capabilities, [])

      test_pid = self()

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          send(test_pid, :transport_was_called)
          {:ok, %{status: 200, headers: [], body: valid_envelope_bytes()}}
        end
      )

      System.put_env("MINIMAX_API_KEY", "")

      repository_root = Path.expand("../..", File.cwd!())

      result =
        Worker.propose(
          valid_assignment(),
          valid_eligibility(),
          valid_profile(),
          valid_request_attrs(),
          repository_root
        )

      assert {:error, %{status: :E_RUNTIME_UNAVAILABLE}} = result
      refute_received :transport_was_called
    end
  end

  describe "positive control — explicit authority grant" do
    test "real_provider + credential + explicit authority → transport may execute (positive control)" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])
      Application.put_env(:kiln, :provider_network_denied_capabilities, [])

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          {:ok, %{status: 200, headers: [], body: valid_envelope_bytes()}}
        end
      )

      System.put_env("MINIMAX_API_KEY", "sentinel-credential")

      repository_root = Path.expand("../..", File.cwd!())

      assert {:ok, _worker_output} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs(),
                 repository_root
               )
    end
  end

  describe "provider capability configuration is runtime-readable" do
    test "the default denied set includes provider.network" do
      Application.delete_env(:kiln, :provider_network_denied_capabilities)
      assert "provider.network" in Worker.provider_network_denied_capabilities()
    end

    test "the default allowed set is empty" do
      Application.delete_env(:kiln, :provider_network_allowed_capabilities)
      assert Worker.provider_network_allowed_capabilities() == []
    end

    test "the credential gate runs before the authority gate" do
      # The credential resolution is in the adapter's fetch_credential/0.
      # The absence of MINIMAX_API_KEY MUST short-circuit before any
      # Authority.decide/1 call. We verify this by observing that the
      # called-once transport counter is NOT incremented.
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])
      Application.put_env(:kiln, :provider_network_denied_capabilities, [])

      test_pid = self()

      Application.put_env(
        :kiln,
        :minimax_transport,
        fn _request, _credential, _opts ->
          send(test_pid, :transport_was_called)
          {:ok, %{status: 200, headers: [], body: valid_envelope_bytes()}}
        end
      )

      System.delete_env("MINIMAX_API_KEY")

      repository_root = Path.expand("../..", File.cwd!())

      _ =
        Worker.propose(
          valid_assignment(),
          valid_eligibility(),
          valid_profile(),
          valid_request_attrs(),
          repository_root
        )

      refute_received :transport_was_called
    end
  end
end
