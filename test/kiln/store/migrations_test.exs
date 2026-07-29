defmodule Kiln.Store.MigrationsTest do
  use ExUnit.Case, async: true

  alias Kiln.Store.{Connection, Migrations}

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-mig-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    {:ok, conn} = Connection.start_link(path: Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(conn) end)

    {:ok, conn: conn, dir: dir}
  end

  test "applies the initial migration on a fresh store", %{conn: conn} do
    assert {:ok, %{version: 1, applied_now: [1]}} =
             Migrations.migrate(conn, now: "2026-07-29T00:00:00Z")

    assert Migrations.current_version(conn) == 1

    tables =
      conn
      |> Connection.query!("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
      |> List.flatten()

    assert "schema_migrations" in tables
    assert "journal_entries" in tables
    assert "action_commits" in tables
    assert "session_projections" in tables
    assert "transcript_records" in tables
  end

  test "records the file checksum for an applied migration", %{conn: conn} do
    {:ok, _} = Migrations.migrate(conn, now: "2026-07-29T00:00:00Z")
    {:ok, [migration]} = Migrations.discover()

    assert [[1, checksum]] =
             Connection.query!(conn, "SELECT version, checksum FROM schema_migrations")

    assert checksum == migration.checksum
  end

  test "is idempotent when already current", %{conn: conn} do
    {:ok, _} = Migrations.migrate(conn, now: "2026-07-29T00:00:00Z")
    assert {:ok, %{version: 1, applied_now: []}} = Migrations.migrate(conn)
  end

  test "blocks when the bundled migration set is absent", %{conn: conn, dir: dir} do
    missing = Path.join(dir, "missing-migrations")

    assert {:error, %{class: :migration, code: :missing_migrations}} =
             Migrations.migrate(conn, dir: missing)

    assert Migrations.current_version(conn) == 0

    assert [] =
             Connection.query!(
               conn,
               "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'journal_entries'"
             )
  end

  test "blocks a modified applied migration", %{conn: conn} do
    {:ok, _} = Migrations.migrate(conn)

    Connection.query!(
      conn,
      "UPDATE schema_migrations SET checksum = 'deadbeef' WHERE version = 1"
    )

    assert {:error, %{class: :migration, code: :checksum_mismatch}} = Migrations.migrate(conn)
  end

  test "blocks a store written by a newer binary", %{conn: conn} do
    {:ok, _} = Migrations.migrate(conn)

    Connection.query!(
      conn,
      "INSERT INTO schema_migrations (version, name, checksum, applied_at) VALUES (9999, 'future', 'x', '2026-07-29T00:00:00Z')"
    )

    assert {:error, %{class: :future_version, code: :unknown_applied_migration}} =
             Migrations.migrate(conn)
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
