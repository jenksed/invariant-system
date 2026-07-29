defmodule Kiln.Restart do
  @moduledoc """
  Startup reconstruction of the current Session from the durable journal.

  Reconstruction rebuilds and reconciles the cached projection inside a
  consistent snapshot, then applies the conservative P0-W21 restart rules: a
  nonterminal external operation with no proved terminal observation reconstructs
  as an unknown operation and an `orphaned` Root Run. It dispatches, replays, or
  simulates no external effect, appends no journal entry, and an incomplete or
  corrupt journal blocks and preserves the database (P1-S01-T03-R07, R08, R09,
  R12).

  For the P1-S01 contract exactly one durable Session is expected. Zero Sessions
  reconstruct as empty and more than one blocks explicitly, rather than silently
  selecting one. Explicit Session listing and resume belong to a later ticket.
  """

  alias Kiln.Journal.Replay
  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.Connection

  @nonterminal_operation_states ["intent_recorded", "started"]

  @type reconstruction :: %{
          session_id: String.t(),
          projection: Session.t(),
          session_revision: non_neg_integer(),
          action_count: non_neg_integer(),
          entry_count: non_neg_integer(),
          first_sequence: non_neg_integer() | nil,
          last_sequence: non_neg_integer() | nil,
          journal_projection_digest: String.t(),
          reconstructed_projection_digest: String.t(),
          journal_head_digest: String.t() | nil,
          cache_status: Store.status(),
          orphaned: boolean()
        }

  @type result ::
          {:ok, :empty}
          | {:ok, reconstruction()}
          | {:error, %{code: atom(), detail: map()}}
          | {:error, %{session_id: String.t(), block: Replay.block()}}

  @doc "Reconstruct the single first-month Session, or report empty, multiple, or blocked."
  @spec reconstruct(Connection.conn()) :: result()
  def reconstruct(conn) do
    case Replay.sessions(conn) do
      [] ->
        {:ok, :empty}

      [session_id] ->
        reconstruct_session(conn, session_id)

      sessions ->
        {:error,
         %{code: :multiple_sessions, detail: %{count: length(sessions), sessions: sessions}}}
    end
  end

  defp reconstruct_session(conn, session_id) do
    case Store.compare(conn, session_id) do
      {:ok, :empty} ->
        {:ok, :empty}

      {:ok, cache_status, report} ->
        {:ok, classify(report, cache_status)}

      {:error, block} ->
        {:error, %{session_id: session_id, block: block}}
    end
  end

  # Conservative classification of a nonterminal operation. This changes the
  # reconstructed result only; the journal and the cache stay pure-journal truth.
  defp classify(report, cache_status) do
    projection = report.projection
    operation = projection["operation"]

    {final, orphaned} =
      if nonterminal?(operation) do
        {orphan(projection, operation), true}
      else
        {projection, false}
      end

    %{
      session_id: report.session_id,
      projection: final,
      session_revision: report.session_revision,
      action_count: report.action_count,
      entry_count: report.entry_count,
      first_sequence: report.first_sequence,
      last_sequence: report.last_sequence,
      # The journal digest describes pure journal truth; the reconstructed digest
      # describes the returned projection, which may carry conservative orphan
      # classification.
      journal_projection_digest: report.projection_digest,
      reconstructed_projection_digest: Session.digest(final),
      journal_head_digest: report.journal_head_digest,
      cache_status: cache_status,
      orphaned: orphaned
    }
  end

  defp nonterminal?(nil), do: false
  defp nonterminal?(operation), do: operation["state"] in @nonterminal_operation_states

  defp orphan(projection, operation) do
    projection
    |> Map.put("operation", Map.put(operation, "state", "unknown"))
    |> Map.update!("run", &Map.put(&1, "state", "orphaned"))
    |> add_unknown(operation["id"])
  end

  # Idempotent: a repeated reconstruction does not add a second marker for the
  # same operation.
  defp add_unknown(projection, operation_id) do
    marker = unknown(operation_id)

    Map.update(projection, "unknowns", [marker], fn existing ->
      if marker in existing, do: existing, else: existing ++ [marker]
    end)
  end

  defp unknown(operation_id) do
    %{
      "kind" => "external_operation",
      "operation_id" => operation_id,
      "reason" => "no_terminal_observation"
    }
  end
end
