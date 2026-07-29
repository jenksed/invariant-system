defmodule Kiln.Journal.Replay do
  @moduledoc """
  Deterministic journal replay: load a Session's entries in sequence order and
  fold them into the current projection, from zero, without trusting any stored
  projection (P1-S01-T03-R01, R02).

  Every entry is validated before it is applied: the payload digest must match
  (corruption), the session revision must be contiguous (missing or out-of-order),
  a reused idempotency key with the same digest is a benign duplicate with no
  extra effect while a different digest is a conflict, the kind must be known, and
  the Run transition must be accepted. The first invalid entry blocks
  reconstruction and reports its exact sequence boundary (P1-S01-T03-R03, R04,
  R05).
  """

  alias Kiln.Journal.Reducer
  alias Kiln.Projections.Session
  alias Kiln.Store.{Canonical, Connection}

  @type rebuild :: %{
          projection: Session.t() | nil,
          session_revision: non_neg_integer() | nil,
          last_sequence: non_neg_integer(),
          entry_count: non_neg_integer()
        }

  @type block :: %{code: atom(), boundary: non_neg_integer() | nil, detail: map()}

  @doc "Distinct Session identifiers present in the journal, in first-seen order."
  @spec sessions(Connection.conn()) :: [String.t()]
  def sessions(conn) do
    conn
    |> Connection.query!(
      "SELECT session_id FROM journal_entries GROUP BY session_id ORDER BY min(sequence)"
    )
    |> List.flatten()
  end

  @doc "Rebuild the projection for `session_id` from sequence zero."
  @spec rebuild(Connection.conn(), String.t()) :: {:ok, rebuild()} | {:error, block()}
  def rebuild(conn, session_id) do
    rows =
      Connection.query!(
        conn,
        """
        SELECT sequence, entry_type, payload, payload_digest, payload_schema,
               session_revision, idempotency_key, request_digest
        FROM journal_entries
        WHERE session_id = ?1
        ORDER BY sequence
        """,
        [session_id]
      )

    initial = %{projection: nil, prev_revision: -1, last_sequence: 0, applied: 0, seen: %{}}

    rows
    |> Enum.reduce_while({:ok, initial}, &step/2)
    |> finish()
  end

  defp step(row, {:ok, acc}) do
    [sequence, type, payload_text, payload_digest, payload_schema, revision, idem_key, req_digest] =
      row

    with {:ok, payload} <- decode(payload_text, sequence),
         :ok <- verify_digest(payload_schema, payload, payload_digest, sequence) do
      case Map.fetch(acc.seen, idem_key) do
        {:ok, ^req_digest} ->
          # Duplicate identical action: no additional projected effect.
          {:cont, {:ok, acc}}

        {:ok, _other_digest} ->
          {:halt, block(:idempotency_conflict, sequence, %{idempotency_key: idem_key})}

        :error ->
          apply_new(acc, sequence, type, payload, revision, idem_key, req_digest)
      end
    else
      {:error, _} = error -> {:halt, error}
    end
  end

  defp apply_new(acc, sequence, type, payload, revision, idem_key, req_digest) do
    cond do
      revision != acc.prev_revision + 1 ->
        {:halt,
         block(:revision_discontinuity, sequence, %{
           expected: acc.prev_revision + 1,
           got: revision
         })}

      true ->
        case Reducer.reduce(acc.projection, %{type: type, payload: payload}) do
          {:ok, projection} ->
            {:cont,
             {:ok,
              %{
                acc
                | projection: projection,
                  prev_revision: revision,
                  last_sequence: sequence,
                  applied: acc.applied + 1,
                  seen: Map.put(acc.seen, idem_key, req_digest)
              }}}

          {:error, %{code: code, detail: detail}} ->
            {:halt, block(code, sequence, detail)}
        end
    end
  end

  defp finish({:ok, %{applied: 0}}) do
    {:ok, %{projection: nil, session_revision: nil, last_sequence: 0, entry_count: 0}}
  end

  defp finish({:ok, acc}) do
    projection = Session.stamp(acc.projection, acc.prev_revision, acc.last_sequence)

    {:ok,
     %{
       projection: projection,
       session_revision: acc.prev_revision,
       last_sequence: acc.last_sequence,
       entry_count: acc.applied
     }}
  end

  defp finish({:error, _} = error), do: error

  defp decode(text, sequence) do
    {:ok, JSON.decode!(text)}
  rescue
    _ -> block(:corrupt_payload, sequence, %{reason: :invalid_json})
  end

  defp verify_digest(schema, payload, expected, sequence) do
    if Canonical.digest(schema, payload) == expected do
      :ok
    else
      block(:corrupt_payload, sequence, %{reason: :digest_mismatch})
    end
  end

  defp block(code, sequence, detail) do
    {:error, %{code: code, boundary: sequence, detail: detail}}
  end
end
