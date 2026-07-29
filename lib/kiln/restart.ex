defmodule Kiln.Restart do
  @moduledoc """
  Startup reconstruction of the current Session from the durable journal.

  Reconstruction rebuilds and reconciles the cached projection, then applies the
  conservative P0-W21 restart rules: a nonterminal external operation with no
  proved terminal observation reconstructs as an unknown operation and an
  `orphaned` Root Run. It dispatches, replays, or simulates no external effect,
  and an incomplete or corrupt journal blocks and preserves the database
  (P1-S01-T03-R07, R08, R09, R12).
  """

  alias Kiln.Journal.Replay
  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.Connection

  @nonterminal_operation_states ["intent_recorded", "started"]

  @type reconstruction :: %{
          session_id: String.t(),
          projection: Session.t(),
          session_revision: non_neg_integer(),
          compare: :match | :rebuilt,
          orphaned: boolean()
        }

  @type result ::
          {:ok, :empty}
          | {:ok, reconstruction()}
          | {:error, %{session_id: String.t() | nil, block: Replay.block()}}

  @doc """
  Reconstruct the single first-month Session, or report an empty or blocked store.
  """
  @spec reconstruct(Connection.conn()) :: result()
  def reconstruct(conn) do
    case Replay.sessions(conn) do
      [] -> {:ok, :empty}
      [session_id | _] -> reconstruct_session(conn, session_id)
    end
  end

  defp reconstruct_session(conn, session_id) do
    case Store.compare(conn, session_id) do
      {:ok, :empty} ->
        {:ok, :empty}

      {:ok, compare, projection} ->
        {:ok, classify(session_id, projection, compare)}

      {:error, block} ->
        {:error, %{session_id: session_id, block: block}}
    end
  end

  # Conservative classification of a nonterminal operation. This changes the
  # reconstructed result only; the journal and the cache stay pure-journal truth.
  defp classify(session_id, projection, compare) do
    operation = projection["operation"]

    if nonterminal?(operation) do
      orphaned =
        projection
        |> Map.put("operation", Map.put(operation, "state", "unknown"))
        |> Map.update!("run", &Map.put(&1, "state", "orphaned"))
        |> add_unknown(operation["id"])

      base(session_id, orphaned, compare, true)
    else
      base(session_id, projection, compare, false)
    end
  end

  defp nonterminal?(nil), do: false
  defp nonterminal?(operation), do: operation["state"] in @nonterminal_operation_states

  defp add_unknown(projection, operation_id) do
    Map.update(projection, "unknowns", [unknown(operation_id)], fn existing ->
      existing ++ [unknown(operation_id)]
    end)
  end

  defp unknown(operation_id) do
    %{
      "kind" => "external_operation",
      "operation_id" => operation_id,
      "reason" => "no_terminal_observation"
    }
  end

  defp base(session_id, projection, compare, orphaned) do
    %{
      session_id: session_id,
      projection: projection,
      session_revision: projection["session_revision"],
      compare: compare,
      orphaned: orphaned
    }
  end
end
