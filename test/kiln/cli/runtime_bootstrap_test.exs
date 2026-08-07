defmodule Kiln.CLI.RuntimeTest do
  use ExUnit.Case, async: false

  alias Kiln.CLI.Runtime
  alias Kiln.Store

  @now "2026-08-06T12:00:00Z"

  setup do
    dir = tmp_home!()
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir}
  end

  test "open/2 :write mode creates the state DB and registers a connection", %{dir: dir} do
    state_path = Path.join(dir, "state.sqlite3")

    assert {:ok, :ready} = Runtime.open(dir, :write)
    assert File.regular?(state_path)
    assert is_pid(Process.whereis(Kiln.Store.Connection))

    Runtime.stop()
    refute Process.whereis(Kiln.Store.Connection)
  end

  test "open/2 :read mode returns :absent and does not create a state DB", %{dir: dir} do
    state_path = Path.join(dir, "state.sqlite3")

    assert {:absent} = Runtime.open(dir, :read)
    refute File.regular?(state_path)
    refute Process.whereis(Kiln.Store.Connection)
  end

  test "open/2 :read mode opens an existing state DB without deleting it", %{dir: dir} do
    state_path = Path.join(dir, "state.sqlite3")
    {:ready, store} = Store.start(path: state_path, store_id: "store_seed", now: @now)
    :ok = GenServer.stop(store.conn)

    assert {:ok, :ready} = Runtime.open(dir, :read)
    assert File.regular?(state_path)
    assert is_pid(Process.whereis(Kiln.Store.Connection))

    Runtime.stop()
  end

  test "stop/0 is idempotent and tolerates a missing connection" do
    refute Process.whereis(Kiln.Store.Connection)
    assert :ok = Runtime.stop()
    assert :ok = Runtime.stop()
  end

  test "module does not depend on Domain, Projections, Journal, Restart, or Workflow" do
    source = File.read!("lib/kiln/cli/runtime_bootstrap.ex")
    code = strip_comments(source)

    forbidden = [
      "Kiln.Domain",
      "Kiln.Projections",
      "Kiln.Journal",
      "Kiln.Restart",
      "Kiln.Workflow",
      ~r/alias\s+Kiln\b(?!\.)/,
      ~r/import\s+Kiln\b/
    ]

    for fragment <- forbidden do
      refute code =~ fragment,
             "runtime_bootstrap.ex must not depend on #{inspect(fragment)} (outside comments)"
    end
  end

  defp strip_comments(source) do
    source
    |> String.split(["\n", "\r\n"])
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp tmp_home! do
    dir = Path.join(System.tmp_dir!(), "kiln-cli-runtime-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    dir
  end
end
