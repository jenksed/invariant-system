defmodule Kiln.Projections.Store do
  @moduledoc """
  Read, classify, and reconcile the cached Session projection.

  A stored projection is only a cache; the journal and its `action_commits` are
  authoritative. `compare/2` rebuilds from the journal and reconciles the cache
  inside one immediate transaction, so the read prefix and any replacement use a
  consistent view (P1-S01-T03-R11). Cache loading is total and never raises: a
  malformed or metadata-inconsistent cache is classified and replaced after the
  journal validates completely. A cache defect alone never blocks reconstruction;
  a journal defect blocks and preserves the database (P1-S01-T03-R12).
  """

  alias Kiln.Journal.Replay
  alias Kiln.Projections.Session
  alias Kiln.Store.{Canonical, Connection}

  @type status ::
          :match | :rebuilt | :replaced_malformed | :replaced_stale | :replaced_invalid_metadata

  @type outcome ::
          {:ok, :empty}
          | {:ok, status(), Replay.report()}
          | {:error, Replay.block()}

  @doc "Load the cached projection for `session_id`, or `nil`. Never raises."
  @spec load(Connection.conn(), String.t()) :: Session.t() | nil
  def load(conn, session_id) do
    case load_record(conn, session_id) do
      nil -> nil
      %{projection: projection} -> projection
      :malformed -> nil
    end
  end

  @doc """
  Rebuild `session_id` from the journal and reconcile the cache in one snapshot.

  Returns `{:ok, :empty}` for a Session with no entries, `{:ok, status, report}`
  where `status` records how the cache was reconciled and `report` is the full
  replay report, or `{:error, block}` when the journal does not validate.
  """
  @spec compare(Connection.conn(), String.t()) :: outcome()
  def compare(conn, session_id) do
    {:ok, outcome} =
      Connection.transaction(conn, fn tx ->
        case Replay.rebuild(tx, session_id) do
          {:ok, %{projection: nil}} -> {:ok, :empty}
          {:ok, %{projection: _} = report} -> reconcile(tx, session_id, report)
          {:error, _block} = error -> error
        end
      end)

    outcome
  end

  # -- reconciliation --

  defp reconcile(tx, session_id, report) do
    case classify(tx, session_id, report.projection) do
      :match ->
        {:ok, :match, report}

      status ->
        write(tx, session_id, report.projection)
        {:ok, status, report}
    end
  end

  # Classify the current cache against the validated rebuild.
  defp classify(tx, session_id, rebuilt) do
    case load_record(tx, session_id) do
      nil -> :rebuilt
      :malformed -> :replaced_malformed
      record -> classify_record(record, rebuilt)
    end
  end

  defp classify_record(record, rebuilt) do
    cond do
      not metadata_consistent?(record) -> :replaced_invalid_metadata
      Session.digest(record.projection) == Session.digest(rebuilt) -> :match
      true -> :replaced_stale
    end
  end

  # Every metadata field must agree: the column schema and revision and sequence,
  # the embedded schema and reducer version, and the stored digest.
  defp metadata_consistent?(record) do
    projection = record.projection

    record.schema == Session.schema() and
      projection["schema"] == Session.schema() and
      projection["reducer_version"] == Session.reducer_version() and
      record.digest == Session.digest(projection) and
      record.session_revision == projection["session_revision"] and
      record.last_sequence == projection["last_sequence"]
  end

  # -- persistence --

  defp load_record(conn, session_id) do
    case Connection.query!(
           conn,
           """
           SELECT projection_schema, session_revision, last_sequence, projection, projection_digest
           FROM session_projections
           WHERE session_id = ?1
           """,
           [session_id]
         ) do
      [] ->
        nil

      [[schema, revision, last_sequence, projection_text, digest]] ->
        case safe_decode(projection_text) do
          {:ok, projection} ->
            %{
              schema: schema,
              session_revision: revision,
              last_sequence: last_sequence,
              projection: projection,
              digest: digest
            }

          :error ->
            :malformed
        end
    end
  end

  defp write(tx, session_id, projection) do
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
        Canonical.encode(projection),
        Session.digest(projection),
        now()
      ]
    )
  end

  defp safe_decode(text) do
    {:ok, JSON.decode!(text)}
  rescue
    _ -> :error
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_iso8601()
end
