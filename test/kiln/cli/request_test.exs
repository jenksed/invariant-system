defmodule Kiln.CLI.RequestTest do
  use ExUnit.Case, async: true

  alias Kiln.CLI.Request

  @actor "test-actor"

  test "parses the start command with all required options" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home",
               "/tmp/kiln-cli-test",
               "--format",
               "json",
               "--actor-id",
               @actor,
               "start",
               "--repo",
               "/tmp/example",
               "--objective",
               "Fix one defect",
               "--criterion",
               "Test passes",
               "--constraint",
               "No new dependencies",
               "--exclude",
               "No provider"
             ])

    assert request.command == :start
    assert request.format == :json
    assert request.kiln_home == "/tmp/kiln-cli-test"
    assert request.actor_id == @actor
    assert request.options["repo"] == "/tmp/example"
    assert request.options["objective"] == "Fix one defect"
    assert request.options["criterion"] == ["Test passes"]
    assert request.options["constraint"] == ["No new dependencies"]
    assert request.options["exclude"] == ["No provider"]
  end

  test "parses equals-separated flag values" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home=/tmp/kiln-cli-test",
               "--format=text",
               "--actor-id=test-actor",
               "status"
             ])

    assert request.kiln_home == "/tmp/kiln-cli-test"
    assert request.format == :text
    assert request.actor_id == @actor
    assert request.command == :status
  end

  test "preserves repeated criteria in argv order" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home=/tmp/x",
               "--actor-id=test-actor",
               "start",
               "--repo=/tmp/repo",
               "--objective=Fix it",
               "--criterion=first",
               "--criterion=second"
             ])

    assert request.options["criterion"] == ["first", "second"]
  end

  test "rejects flags that are not authorized for the command" do
    assert {:error, error} =
             Request.parse([
               "--kiln-home=/tmp/x",
               "--actor-id=test-actor",
               "status",
               "--reason=nope"
             ])

    assert error.message =~ "unknown flag for status"
  end

  test "rejects missing start inputs during parsing" do
    assert {:error, error} =
             Request.parse([
               "--kiln-home=/tmp/x",
               "--actor-id=test-actor",
               "start",
               "--repo=/tmp/repo"
             ])

    assert error.message =~ "--objective is required"
  end

  test "marks the help request when only --help is given" do
    assert {:ok, request} = Request.parse(["--help"])
    assert request.show_help == true
    assert request.command == nil
  end

  test "marks the version request when only --version is given" do
    assert {:ok, request} = Request.parse(["--version"])
    assert request.show_version == true
    assert request.command == nil
  end

  test "rejects unknown commands with a structured USAGE_ERROR" do
    assert {:error, error} =
             Request.parse(["--kiln-home=/tmp/x", "--actor-id=test-actor", "patch.inspect"])

    assert error.code == "USAGE_ERROR"
    assert error.class == "usage"
    assert error.message =~ "unsupported command"
  end

  test "rejects unknown flags before the command with a structured USAGE_ERROR" do
    assert {:error, error} =
             Request.parse(["--kiln-home=/tmp/x", "--actor-id=test-actor", "--bogus", "status"])

    assert error.code == "USAGE_ERROR"
    assert error.message =~ "unknown flag"
  end

  test "treats --kiln-home with no value as a missing required command" do
    assert {:error, error} = Request.parse(["--kiln-home"])
    assert error.message =~ "--kiln-home requires a path value"
  end

  test "rejects --kiln-home whose next value happens to look like a command" do
    # The parser now rejects any relative literal value (CLI contract).
    # The word "status" is not an absolute path.
    assert {:error, error} = Request.parse(["--kiln-home", "status"])
    assert error.message =~ "absolute"
  end

  test "rejects --format with an unsupported value" do
    assert {:error, error} =
             Request.parse([
               "--kiln-home=/tmp/x",
               "--actor-id=test-actor",
               "--format=xml",
               "status"
             ])

    assert error.message =~ "--format must be text or json"
  end

  test "requires a command unless --help or --version is requested" do
    assert {:error, error} =
             Request.parse(["--kiln-home=/tmp/x", "--actor-id=test-actor"])

    assert error.message =~ "a command is required"
  end

  # -- actor_id: explicit, env, blank, missing --

  test "parses --actor-id explicitly" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home=/tmp/x",
               "--actor-id=user:local",
               "status"
             ])

    assert request.actor_id == "user:local"
  end

  test "falls back to KILN_ACTOR_ID when --actor-id is absent" do
    System.put_env("KILN_ACTOR_ID", "user:env")

    try do
      assert {:ok, request} = Request.parse(["--kiln-home=/tmp/x", "status"])
      assert request.actor_id == "user:env"
    after
      System.delete_env("KILN_ACTOR_ID")
    end
  end

  test "KILN_ACTOR_ID is overridden when --actor-id is supplied" do
    System.put_env("KILN_ACTOR_ID", "user:env")

    try do
      assert {:ok, request} =
               Request.parse([
                 "--kiln-home=/tmp/x",
                 "--actor-id=user:cli",
                 "status"
               ])

      assert request.actor_id == "user:cli"
    after
      System.delete_env("KILN_ACTOR_ID")
    end
  end

  test "rejects missing --actor-id with no KILN_ACTOR_ID set" do
    System.delete_env("KILN_ACTOR_ID")

    assert {:error, error} = Request.parse(["--kiln-home=/tmp/x", "status"])
    assert error.code == "USAGE_ERROR"
    assert error.message =~ "actor_id is required"
  end

  test "rejects explicit --actor-id with a blank value" do
    assert {:error, error} =
             Request.parse(["--kiln-home=/tmp/x", "--actor-id=", "status"])

    assert error.code == "USAGE_ERROR"
    assert error.message =~ "--actor-id"
  end

  test "rejects explicit --actor-id with only whitespace" do
    assert {:error, error} =
             Request.parse(["--kiln-home=/tmp/x", "--actor-id=   ", "status"])

    assert error.code == "USAGE_ERROR"
    assert error.message =~ "--actor-id"
  end

  # -- kiln_home canonicalisation --

  test "rejects relative --kiln-home with a structured USAGE_ERROR" do
    assert {:error, error} =
             Request.parse([
               "--kiln-home=./relative/path",
               "--actor-id=test-actor",
               "status"
             ])

    assert error.code == "USAGE_ERROR"
    assert error.message =~ "absolute"
  end

  test "collapses `..` segments inside an absolute --kiln-home" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home=/tmp/a/b/../c",
               "--actor-id=test-actor",
               "status"
             ])

    assert request.kiln_home == "/tmp/a/c"
  end

  test "preserves an already-absolute --kiln-home path" do
    assert {:ok, request} =
             Request.parse([
               "--kiln-home=/tmp/already/absolute",
               "--actor-id=test-actor",
               "status"
             ])

    assert request.kiln_home == "/tmp/already/absolute"
  end

  # KILN_HOME precedence: explicit flag → KILN_HOME env → default home.
  # The dispatcher must never receive a `nil` `kiln_home`.

  describe "KILN_HOME precedence (CLI-AND-LOCAL-DELIVERY-CONTRACT.md §3.1)" do
    test "falls back to KILN_HOME env when --kiln-home is absent" do
      env = fn "KILN_HOME" -> "/tmp/from-kiln-home-env" end

      assert {:ok, request} =
               Request.parse(
                 ["--actor-id=test-actor", "status"],
                 env
               )

      assert request.kiln_home == "/tmp/from-kiln-home-env"
    end

    test "explicit --kiln-home overrides KILN_HOME env" do
      env = fn "KILN_HOME" -> "/tmp/from-env" end

      assert {:ok, request} =
               Request.parse(
                 ["--kiln-home=/tmp/explicit", "--actor-id=test-actor", "status"],
                 env
               )

      assert request.kiln_home == "/tmp/explicit"
    end

    test "falls back to ~/Library/Application Support/Kiln when env is unset" do
      env = fn _ -> nil end

      assert {:ok, request} =
               Request.parse(
                 ["--actor-id=test-actor", "status"],
                 env
               )

      assert request.kiln_home ==
               Path.expand("~/Library/Application Support/Kiln") |> Path.absname()
    end

    test "blank KILN_HOME env falls back to default" do
      env = fn "KILN_HOME" -> "" end

      assert {:ok, request} =
               Request.parse(
                 ["--actor-id=test-actor", "status"],
                 env
               )

      assert request.kiln_home ==
               Path.expand("~/Library/Application Support/Kiln") |> Path.absname()
    end

    test "relative KILN_HOME env is rejected with a structured USAGE_ERROR" do
      env = fn "KILN_HOME" -> "relative/path" end

      assert {:error, error} =
               Request.parse(
                 ["--actor-id=test-actor", "status"],
                 env
               )

      assert error.code == "USAGE_ERROR"
      assert error.message =~ "--kiln-home"
    end
  end
end
