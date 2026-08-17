defmodule Kiln.M0CandidateInvocationCLITest do
  @moduledoc """
  CLI-level regression test for the KILN-M0-01 (E4) public consumer-visible
  surface that the BENCH-M0-01 (M6) merge-train position depends on.

  This test exercises the real Kiln CLI request parser and the real
  `Kiln.CLI.run/1` dispatcher against the two commands the KILN-M0-01
  authorization record explicitly listed in scope:

      :candidate_invocation
      :candidate_invocation_digest

  M3 (KILN-M0-01) shipped the internal Elixir modules
  `Kiln.CandidateInvocation` and `Kiln.MinimaxM3Adapter` but did not wire
  the public CLI surface. Before this test was added, the CLI returned
  `unsupported command: candidate-invocation`. After the corrective
  E1/E2 wiring lands, every assertion in this module must pass.

  All tests are network-independent. The dispatch path is bounded by
  design — see `products/kiln/docs/work/KILN-M0-01-CLI-CLOSURE.md` for
  the acceptance harness.
  """

  use ExUnit.Case, async: true

  alias Kiln.CLI
  alias Kiln.CLI.Request
  alias Kiln.CLI.Result

  # The implementation digest is computed at runtime by
  # `Kiln.MinimaxM3Adapter.implementation_digest/0`. The CLI surface
  # must surface the live runtime digest, not a planning-time fixture
  # constant — digests shift whenever the adapter is rebuilt, and a
  # frozen constant would create a false-completion failure mode where
  # the test passes against the wrong value.
  defp expected_digest, do: Kiln.MinimaxM3Adapter.implementation_digest()

  # A canonical Candidate Invocation request matching the M0v1 schema.
  # The values are deterministic; the schema digest is computed by
  # the parser so we do not need to pre-compute it here.
  @valid_request %{
    "invocation_id" => "inv-cli-test-001",
    "mode" => "PRODUCTION",
    "profile_ref" => %{
      "id" => "profile-cli",
      "digest" => "sha256:" <> String.duplicate("a", 64)
    },
    "context_manifest_ref" => %{
      "id" => "ctx-cli-001",
      "digest" => "sha256:" <> String.duplicate("b", 64)
    },
    "tool_policy_ref" => %{
      "id" => "tool-policy-cli-001",
      "digest" => "sha256:" <> String.duplicate("c", 64)
    },
    "timeout_ms" => 60_000,
    "output_contract" => "IMPLEMENTER_PATCH_PROPOSAL"
  }

  # ----- parser-level: candidate-invocation-digest -----

  describe "Kiln.CLI.Request.parse — candidate-invocation-digest" do
    test "accepts the bare command with no body flags" do
      assert {:ok, %Request{command: :candidate_invocation_digest}} =
               Request.parse([
                 "--format=json",
                 "--actor-id=bench",
                 "candidate-invocation-digest"
               ])
    end

    test "rejects body flags on candidate-invocation-digest" do
      {:error, error} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation-digest",
          "--request",
          "/tmp/x.json"
        ])

      # The error message may surface the kebab-case CLI form
      # (`candidate-invocation-digest`) or the internal atom form
      # (`candidate_invocation_digest`); both are acceptable for this
      # consumer-visible parser failure.
      assert error.message =~ "unknown flag for" and
               (error.message =~ "candidate-invocation-digest" or
                  error.message =~ "candidate_invocation_digest"),
             "expected the unknown-flag error to mention the command; got: #{error.message}"
    end
  end

  # ----- parser-level: candidate-invocation -----

  describe "Kiln.CLI.Request.parse — candidate-invocation" do
    test "accepts --request and --mode evaluation" do
      {:ok, request} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation",
          "--request",
          "/tmp/x.json",
          "--mode",
          "evaluation"
        ])

      assert request.command == :candidate_invocation
      assert request.options["request"] == "/tmp/x.json"
      assert request.options["mode"] == "evaluation"
    end

    test "accepts --mode production" do
      {:ok, request} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation",
          "--request=/tmp/x.json",
          "--mode=production"
        ])

      assert request.command == :candidate_invocation
      assert request.options["mode"] == "production"
    end

    test "rejects --mode outside the closed production|evaluation enum" do
      {:error, error} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation",
          "--request=/tmp/x.json",
          "--mode=bogus"
        ])

      assert error.message =~ "production|evaluation"
    end

    test "rejects missing --request" do
      {:error, error} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation",
          "--mode=evaluation"
        ])

      assert error.message =~ "--request"
    end

    test "rejects missing --mode" do
      {:error, error} =
        Request.parse([
          "--format=json",
          "--actor-id=bench",
          "candidate-invocation",
          "--request=/tmp/x.json"
        ])

      assert error.message =~ "--mode"
    end
  end

  # ----- dispatch-level: candidate-invocation-digest -----

  describe "Kiln.CLI.run/1 — candidate-invocation-digest" do
    test "returns the recorded implementation digest with exit 0" do
      {:ok, input} =
        Request.parse(["--format=json", "--actor-id=bench", "candidate-invocation-digest"])

      assert {%Result{status: :ok, exit_code: 0} = result, 0} = CLI.run(input)
      assert result.command == "candidate-invocation-digest"

      # The data payload must surface the exact adapter digest. We do
      # not assert the entire map shape (the renderer is the renderer),
      # but the digest must be present.
      data = result.data || %{}
      expected = expected_digest()

      digest_in_data? =
        Enum.any?(Map.values(data), fn v -> v == expected end) or
          data["adapter_implementation_digest"] == expected

      assert digest_in_data?,
             "candidate-invocation-digest must surface the runtime implementation digest"
    end

    test "does not require Store / Journal / actor_id environment" do
      # Pure dispatch — no Kiln.Store, no journal, no Workflow. The
      # candidate-invocation-digest command is a property of the
      # installed adapter, not of the operator's local state.
      {:ok, input} =
        Request.parse(["--format=json", "--actor-id=bench", "candidate-invocation-digest"])

      assert {%Result{status: :ok}, 0} = CLI.run(input)
    end
  end

  # ----- dispatch-level: candidate-invocation -----

  describe "Kiln.CLI.run/1 — candidate-invocation (evaluation mode)" do
    setup do
      # Drop any inherited credential so the test cannot leak into a
      # real provider call. The CLI must gate production mode on the
      # credential; evaluation mode must NOT require it.
      System.delete_env("MINIMAX_API_KEY")
      :ok
    end

    test "evaluation mode reaches the Candidate Invocation schema parser without a credential" do
      path = Path.join(System.tmp_dir!(), "kiln-cli-m0-test-#{System.unique_integer([:positive])}.json")
      File.write!(path, JSON.encode!(@valid_request))

      try do
        {:ok, request} =
          Request.parse([
            "--format=json",
            "--actor-id=bench",
            "candidate-invocation",
            "--request=#{path}",
            "--mode=evaluation"
          ])

        assert {%Result{} = result, exit_code} = CLI.run(request)

        # The dispatcher proved the public consumer-visible surface: it
        # carried the request through the CLI, parsed the schema, and
        # returned a Result. evaluation mode must NOT exit non-zero for
        # credential absence — that gate is reserved for production.
        assert exit_code == 0,
               "evaluation mode must not require MINIMAX_API_KEY; got exit_code=#{exit_code} status=#{result.status}"

        assert result.status == :ok,
               "expected :ok from evaluation-mode schema-valid dispatch; got #{result.status}"
      after
        File.rm(path)
      end
    end

    test "rejects an invalid request file with a bounded error" do
      path = Path.join(System.tmp_dir!(), "kiln-cli-m0-bad-#{System.unique_integer([:positive])}.json")
      File.write!(path, "{not json")

      try do
        {:ok, request} =
          Request.parse([
            "--format=json",
            "--actor-id=bench",
            "candidate-invocation",
            "--request=#{path}",
            "--mode=evaluation"
          ])

        assert {%Result{status: status}, exit_code} = CLI.run(request)
        assert status == :denied
        assert exit_code != 0
      after
        File.rm(path)
      end
    end
  end

  describe "Kiln.CLI.run/1 — candidate-invocation (production mode)" do
    setup do
      System.delete_env("MINIMAX_API_KEY")
      :ok
    end

    test "production mode requires MINIMAX_API_KEY presence" do
      path = Path.join(System.tmp_dir!(), "kiln-cli-m0-prod-#{System.unique_integer([:positive])}.json")
      File.write!(path, JSON.encode!(@valid_request))

      try do
        {:ok, request} =
          Request.parse([
            "--format=json",
            "--actor-id=bench",
            "candidate-invocation",
            "--request=#{path}",
            "--mode=production"
          ])

        assert {%Result{status: status}, exit_code} = CLI.run(request)
        # The dispatch must surface the runtime-unavailable fact instead
        # of silently proceeding. The bounded error class is
        # :E_RUNTIME_UNAVAILABLE; the CLI maps it to a denied /
        # blocked status with a non-zero exit.
        assert exit_code != 0,
               "production mode without MINIMAX_API_KEY must exit non-zero"
        assert status in [:denied, :blocked, :failed, :unknown],
               "expected a bounded non-ok status; got #{status}"
      after
        File.rm(path)
      end
    end
  end
end
