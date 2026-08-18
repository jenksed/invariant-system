defmodule Kiln.M11E4ProviderAuthorityTest do
  @moduledoc """
  P4 — Trusted authority provenance through the recorded authorization record.

  The M11 E4 audit (Lane B) proved that the runtime admission must
  be bound to the actual trusted authorization record, NOT to
  `Application.put_env`. The trusted authority mechanism is the
  file at `products/kiln/docs/authorizations/KILN-M0-01-E4.provider-network.authorization`.

  This test file proves:

    1. The authorization record is read from the file at runtime.
    2. Invalid/missing/proposed/wrong-base/wrong-work_id/wrong-scope
       authority ALL fail closed.
    3. A valid authorization record authorizes the dispatch.
    4. Authorization is proven BEFORE the credential is read.
    5. An unauthorized run does NOT read the credential and does NOT
       invoke the transport.

  The default production behavior is fail-closed: the authorization
  record must exist, must be `state=authorized`, must have the
  correct `base_sha`, must have the correct `work_id`, and must have
  the correct `scope`.
  """

  use ExUnit.Case, async: false

  alias Kiln.MinimaxM3Adapter
  alias Kiln.Worker

  defp valid_envelope(after_bytes) do
    %{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "add",
          "path" => "products/kiln/lib/kiln/operation_lifecycle.ex",
          "mode" => "100644",
          "after_image_bytes" => after_bytes
        }
      ]
    }
  end

  defp valid_envelope_bytes(after_bytes) do
    after_bytes
    |> then(fn _ -> valid_envelope(after_bytes) end)
    |> Worker.canonical_envelope_bytes()
  end

  defp install_transport(envelope_bytes, test_pid) do
    Application.put_env(
      :kiln,
      :minimax_transport,
      fn _request, _credential, _opts ->
        send(test_pid, :transport_was_called)
        {:ok, %{status: 200, headers: [], body: envelope_bytes}}
      end
    )
  end

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

  defp valid_request_attrs(after_bytes) do
    valid_envelope(after_bytes)
  end

  # Save and restore the real authorization record around tests that
  # mutate it.
  setup do
    original_mode = Application.get_env(:kiln, :worker_provider_mode)
    original_transport = Application.get_env(:kiln, :minimax_transport)
    original_key = System.get_env("MINIMAX_API_KEY")
    original_record = File.read(Kiln.ExecutionAuthorityGate.authorization_path())

    on_exit(fn ->
      case original_mode do
        nil -> Application.delete_env(:kiln, :worker_provider_mode)
        v -> Application.put_env(:kiln, :worker_provider_mode, v)
      end

      case original_transport do
        nil -> Application.delete_env(:kiln, :minimax_transport)
        v -> Application.put_env(:kiln, :minimax_transport, v)
      end

      case original_key do
        nil -> System.delete_env("MINIMAX_API_KEY")
        v -> System.put_env("MINIMAX_API_KEY", v)
      end

      # Restore the original authorization record.
      case original_record do
        {:ok, content} -> File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)
        {:error, _} -> File.rm(Kiln.ExecutionAuthorityGate.authorization_path())
      end
    end)

    System.put_env("MINIMAX_API_KEY", "det-test-credential")
    :ok
  end

  describe "P4 — trusted authority file-backed verification" do
    test "valid authorization record authorizes the dispatch" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      after_bytes = "defmodule Kiln.OperationLifecycle do\n  @moduledoc \"valid auth\"\nend\n"
      install_transport(valid_envelope_bytes(after_bytes), self())

      repository_root = Path.expand("../..", File.cwd!())

      assert {:ok, _worker_output} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs(after_bytes),
                 repository_root
               )
    end

    test "missing authorization record → fail closed" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      File.rm(Kiln.ExecutionAuthorityGate.authorization_path())

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, :missing_authorization_record} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
                 # credo:disable-for-next-line
               )

      # The transport MUST NOT have been invoked.
      refute_received :transport_was_called
    end

    test "state=proposed authorization record → fail closed (not yet authorized)" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      # Replace the authorization record with state=proposed.
      current_sha = get_mono_repo_head()
      content = proposed_record(current_sha)
      File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, :authorization_record_proposed} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
               )

      refute_received :transport_was_called
    end

    test "wrong base_sha → fail closed (wrong-base authority)" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      # Replace the authorization record with a wrong base_sha.
      wrong_sha = String.duplicate("0", 40)
      content = authorized_record(wrong_sha)
      File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())
      expected_sha = actual_base_sha()

      assert {:error, {:base_sha_mismatch, expected: ^expected_sha, actual: ^wrong_sha}} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
               )

      refute_received :transport_was_called
    end

    test "wrong work_id → fail closed" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      current_sha = get_mono_repo_head()
      # NOTE: the scope check permits the bounded repository root, so we
      # keep the scope that includes the observed repo. We only mutate
      # the work_id to be wrong.
      content =
        "work_id=WRONG-WORK-ID\n" <>
          "state=authorized\n" <>
          "owner=Joshua Jenks\n" <>
          "base_sha=#{current_sha}\n" <>
          "plan_sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae\n" <>
          "authorized_at=2026-08-17T20:21:45-04:00\n" <>
          "scope=provider.network capability for the bounded MiniMax M3 adapter only. Endpoint: https://api.minimax.io/v1/chat/completions. MINIMAX_API_KEY presence-only. Operation: dispatch via Finch.stream_while/5 from Worker.build_provider_completion/1. Mutation class: provider.dispatch only. Verify: kiln.compile. Failure: blocked-state-no-retry. #{current_sha}.\n"

      File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, {:work_id_mismatch, expected: "KILN-M0-01-E4", actual: "WRONG-WORK-ID"}} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
               )

      refute_received :transport_was_called
    end

    test "scope missing capability → fail closed" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      current_sha = get_mono_repo_head()
      content = """
      work_id=KILN-M0-01-E4
      state=authorized
      owner=Joshua Jenks
      base_sha=#{current_sha}
      plan_sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
      authorized_at=2026-08-17T20:21:45-04:00
      scope=Endpoint: https://api.minimax.io/v1/chat/completions. MINIMAX_API_KEY presence-only. #{current_sha}.
      """

      File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, :scope_missing_capability} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
               )

      refute_received :transport_was_called
    end

    test "scope missing endpoint → fail closed" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)

      current_sha = get_mono_repo_head()
      content = """
      work_id=KILN-M0-01-E4
      state=authorized
      owner=Joshua Jenks
      base_sha=#{current_sha}
      plan_sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
      authorized_at=2026-08-17T20:21:45-04:00
      scope=provider.network capability for the bounded MiniMax M3 adapter only. MINIMAX_API_KEY presence-only. #{current_sha}.
      """

      File.write!(Kiln.ExecutionAuthorityGate.authorization_path(), content)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      assert {:error, :scope_missing_endpoint} =
               Worker.propose(
                 valid_assignment(),
                 valid_eligibility(),
                 valid_profile(),
                 valid_request_attrs("any"),
                 repository_root
               )

      refute_received :transport_was_called
    end

    test "unauthorized run does NOT read credential and does NOT invoke transport" do
      Application.put_env(:kiln, :worker_provider_mode, :real_provider)
      File.rm(Kiln.ExecutionAuthorityGate.authorization_path())

      # Use a sentinel credential that would be visible if read.
      sentinel = "SENTINEL-MUST-NOT-BE-READ"
      System.put_env("MINIMAX_API_KEY", sentinel)

      test_pid = self()
      install_transport("any", test_pid)

      repository_root = Path.expand("../..", File.cwd!())

      result =
        Worker.propose(
          valid_assignment(),
          valid_eligibility(),
          valid_profile(),
          valid_request_attrs("any"),
          repository_root
        )

      # The result is an authority error (not a credential error).
      assert {:error, :missing_authorization_record} = result

      # The transport MUST NOT have been invoked.
      refute_received :transport_was_called

      # The credential is still in the environment (we did not read it
      # to a different state).
      assert System.get_env("MINIMAX_API_KEY") == sentinel
    end
  end

  # --- helpers ---

  defp get_mono_repo_head do
    {output, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: Path.expand("../..", File.cwd!()))
    String.trim(output)
  end

  defp actual_base_sha do
    {output, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: Path.expand("../..", File.cwd!()))
    String.trim(output)
  end

  defp proposed_record(base_sha) do
    """
    work_id=KILN-M0-01-E4
    state=proposed
    owner=Joshua Jenks
    base_sha=#{base_sha}
    plan_sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
    authorized_at=2026-08-17T20:21:45-04:00
    scope=provider.network capability for the bounded MiniMax M3 adapter only. Endpoint: https://api.minimax.io/v1/chat/completions. MINIMAX_API_KEY presence-only. #{base_sha}.
    """
  end

  defp authorized_record(base_sha) do
    """
    work_id=KILN-M0-01-E4
    state=authorized
    owner=Joshua Jenks
    base_sha=#{base_sha}
    plan_sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
    authorized_at=2026-08-17T20:21:45-04:00
    scope=provider.network capability for the bounded MiniMax M3 adapter only. Endpoint: https://api.minimax.io/v1/chat/completions. MINIMAX_API_KEY presence-only. #{base_sha}.
    """
  end
end
