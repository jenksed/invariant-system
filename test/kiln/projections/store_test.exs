defmodule Kiln.Projections.StoreTest do
  use ExUnit.Case, async: true

  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-proj-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)

    d = JB.domain()
    {:ok, conn: store.conn, d: d}
  end

  test "reports an empty Session with no journal entries", %{conn: conn, d: d} do
    assert {:ok, :empty} = Store.compare(conn, d.session.id)
  end

  test "accepts a cache that already matches the rebuild", %{conn: conn, d: d} do
    {:ok, _} = JB.commit_start(conn_store(conn), d)
    assert {:ok, :match, _projection} = Store.compare(conn, d.session.id)
  end

  test "rebuilds a missing cache from the journal", %{conn: conn, d: d} do
    {:ok, _} = JB.commit_start(conn_store(conn), d)

    Connection.query!(conn, "DELETE FROM session_projections WHERE session_id = ?1", [
      d.session.id
    ])

    assert {:ok, :rebuilt, rebuilt} = Store.compare(conn, d.session.id)
    assert Session.digest(Store.load(conn, d.session.id)) == Session.digest(rebuilt)
  end

  test "replaces a stale cache after the journal validates", %{conn: conn, d: d} do
    {:ok, _} = JB.commit_start(conn_store(conn), d)

    Connection.query!(
      conn,
      "UPDATE session_projections SET projection = '{\"stale\":true}', projection_digest = 'bad' WHERE session_id = ?1",
      [d.session.id]
    )

    assert {:ok, :rebuilt, rebuilt} = Store.compare(conn, d.session.id)
    assert Session.digest(Store.load(conn, d.session.id)) == Session.digest(rebuilt)
  end

  test "blocks on a corrupt journal and preserves the cache", %{conn: conn, d: d} do
    {:ok, _} = JB.commit_start(conn_store(conn), d)
    original = Store.load(conn, d.session.id)

    Connection.query!(
      conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    assert {:error, %{code: :corrupt_payload}} = Store.compare(conn, d.session.id)
    # The cache is not replaced from an invalid journal.
    assert Session.digest(Store.load(conn, d.session.id)) == Session.digest(original)
  end

  defp conn_store(conn), do: %{conn: conn}

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
