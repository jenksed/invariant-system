defmodule Kiln.Store.ConnectionTest do
  use ExUnit.Case, async: true

  alias Kiln.Store.Connection

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-store-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, path: Path.join(dir, "state.sqlite3"), dir: dir}
  end

  test "opens the accepted settings and verifies them on a fresh directory", %{path: path} do
    {:ok, conn} = Connection.start_link(path: path)

    assert {:ok, info} = Connection.verify(conn)
    assert info.journal_mode == "wal"
    assert info.synchronous == 2
    assert info.foreign_keys == 1
    assert info.busy_timeout == 2000
    assert info.quick_check == "ok"
  end

  test "reports the exact bundled SQLite version at or above the accepted baseline", %{path: path} do
    {:ok, conn} = Connection.start_link(path: path)

    assert {:ok, %{sqlite_version: version}} = Connection.verify(conn)

    parts = version |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
    assert parts >= {3, 51, 3}, "expected bundled SQLite >= 3.51.3, got #{version}"
  end

  test "creates the live database file set", %{path: path} do
    {:ok, conn} = Connection.start_link(path: path)
    # Force a write so WAL files materialize.
    Connection.query!(conn, "CREATE TABLE probe (id INTEGER PRIMARY KEY)")

    assert File.exists?(path)
    assert File.exists?(path <> "-wal")
  end

  test "advertises the accepted one-writer immediate-transaction settings" do
    settings = Connection.settings()
    assert settings.pool_size == 1
    assert settings.journal_mode == :wal
    assert settings.synchronous == :full
    assert settings.foreign_keys == :on
    assert settings.busy_timeout_ms == 2000
    assert settings.default_transaction_mode == :immediate
  end
end
