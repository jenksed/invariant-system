defmodule Kiln.Projections.Store do
  @moduledoc """
  Read, compare, and replace the cached Session projection.

  A stored projection is only a cache. `compare/2` rebuilds from the journal,
  and the cache is replaced only after the journal validates completely, so an
  incomplete or corrupt journal blocks and the cache is never treated as more
  authoritative than the log (P1-S01-T03-R11, R12).
  """

  alias Kiln.Journal.Replay
  alias Kiln.Projections.Session
  alias Kiln.Store.Connection

  @type outcome ::
          {:ok, :empty}
          | {:ok, :match, Session.t()}
          | {:ok, :rebuilt, Session.t()}
          | {:error, Replay.block()}

  @doc "Load the cached projection for `session_id`, or `nil` when absent."
  @spec load(Connection.conn(), String.t()) :: Session.t() | nil
  def load(conn, session_id) do
    case Connection.query!(
           conn,
           "SELECT projection FROM session_projections WHERE session_id = ?1",
           [session_id]
         ) do
      [] -> nil
      [[projection_json]] -> JSON.decode!(projection_json)
    end
  end

  @doc """
  Rebuild `session_id` from the journal and reconcile the cache.

  Returns `{:ok, :empty}` when the Session has no journal entries, `{:ok, :match,
  projection}` when the cache already equals the rebuild, `{:ok, :rebuilt,
  projection}` when a missing or stale cache was replaced with the validated
  rebuild, or `{:error, block}` when the journal does not validate.
  """
  @spec compare(Connection.conn(), String.t()) :: outcome()
  def compare(conn, session_id) do
    with {:ok, %{projection: rebuilt}} <- Replay.rebuild(conn, session_id) do
      reconcile(conn, session_id, rebuilt)
    end
  end

  @doc "Replace the cached projection with `projection` in one immediate transaction."
  @spec replace(Connection.conn(), String.t(), Session.t(), String.t()) :: :ok
  def replace(conn, session_id, projection, now) do
    {:ok, :ok} =
      Connection.transaction(conn, fn tx ->
        write(tx, session_id, projection, now)
        :ok
      end)

    :ok
  end

  defp reconcile(_conn, _session_id, nil), do: {:ok, :empty}

  defp reconcile(conn, session_id, rebuilt) do
    stored = load(conn, session_id)

    cond do
      stored == nil ->
        replace(conn, session_id, rebuilt, now())
        {:ok, :rebuilt, rebuilt}

      Session.digest(stored) == Session.digest(rebuilt) ->
        {:ok, :match, rebuilt}

      true ->
        replace(conn, session_id, rebuilt, now())
        {:ok, :rebuilt, rebuilt}
    end
  end

  defp write(tx, session_id, projection, now) do
    Connection.query!(
      tx,
      """
      INSERT INTO session_projections
        (session_id, projection_schema, session_revision, last_sequence, projection, projection_digest, updated_at)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
      ON CONFLICT (session_id) DO UPDATE SET
        projection_schema = excluded.projection_schema,
        session_revision = excluded.session_revision,
        last_sequence = excluded.last_sequence,
        projection = excluded.projection,
        projection_digest = excluded.projection_digest,
        updated_at = excluded.updated_at
      """,
      [
        session_id,
        Session.schema(),
        projection["session_revision"],
        projection["last_sequence"],
        Kiln.Store.Canonical.encode(projection),
        Session.digest(projection),
        now
      ]
    )
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_iso8601()
end
