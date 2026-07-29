defmodule Kiln.Projections.StoreTest do
  use ExUnit.Case, async: true

  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.{Canonical, Connection}
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-proj-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)

    d = JB.domain()
    {:ok, store: store, conn: store.conn, d: d}
  end

  test "reports an empty Session with no journal entries", %{conn: conn, d: d} do
    assert {:ok, :empty} = Store.compare(conn, d.session.id)
  end

  test "accepts a cache that already matches the rebuild", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    assert {:ok, :match, report} = Store.compare(store.conn, d.session.id)

    assert Session.digest(report.projection) ==
             Session.digest(Store.load(store.conn, d.session.id))
  end

  test "rebuilds a missing cache", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    Connection.query!(store.conn, "DELETE FROM session_projections WHERE session_id = ?1", [
      d.session.id
    ])

    assert {:ok, :rebuilt, report} = Store.compare(store.conn, d.session.id)

    assert Session.digest(Store.load(store.conn, d.session.id)) ==
             Session.digest(report.projection)
  end

  test "replaces a malformed cache without raising", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    Connection.query!(
      store.conn,
      "UPDATE session_projections SET projection = 'not json' WHERE session_id = ?1",
      [d.session.id]
    )

    # load is total and never raises.
    assert Store.load(store.conn, d.session.id) == nil

    assert {:ok, :replaced_malformed, report} = Store.compare(store.conn, d.session.id)

    assert Session.digest(Store.load(store.conn, d.session.id)) ==
             Session.digest(report.projection)
  end

  test "replaces a cache whose metadata is inconsistent", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    Connection.query!(
      store.conn,
      "UPDATE session_projections SET session_revision = 999 WHERE session_id = ?1",
      [d.session.id]
    )

    assert {:ok, :replaced_invalid_metadata, _report} = Store.compare(store.conn, d.session.id)
  end

  test "replaces a stale but internally consistent cache", %{store: store, d: d} do
    {:ok, r0} = JB.commit_start(store, d)
    {:ok, _r1} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    # Overwrite the cache with the earlier, self-consistent revision-0 projection.
    proj0 = r0.projection

    Connection.query!(
      store.conn,
      "UPDATE session_projections SET session_revision = ?1, last_sequence = ?2, projection = ?3, projection_digest = ?4 WHERE session_id = ?5",
      [
        proj0["session_revision"],
        proj0["last_sequence"],
        Canonical.encode(proj0),
        Session.digest(proj0),
        d.session.id
      ]
    )

    assert {:ok, :replaced_stale, report} = Store.compare(store.conn, d.session.id)
    assert report.session_revision == 1

    assert Session.digest(Store.load(store.conn, d.session.id)) ==
             Session.digest(report.projection)
  end

  test "blocks on a corrupt journal and preserves the cache", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    original = Store.load(store.conn, d.session.id)

    Connection.query!(
      store.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    assert {:error, %{code: :corrupt_payload}} = Store.compare(store.conn, d.session.id)
    assert Session.digest(Store.load(store.conn, d.session.id)) == Session.digest(original)
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
