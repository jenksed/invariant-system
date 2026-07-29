defmodule Kiln.Projections.Session do
  @moduledoc """
  The current first-month Session projection: shape, schema, reducer version,
  digest, and revision/sequence stamping.

  A projection is plain string-keyed data so the same logical state always
  encodes to the same canonical bytes. The committer and the replay rebuild both
  stamp the same journal sequence and reducer version, so a stored projection and
  a fresh rebuild are byte-for-byte comparable (P1-S01-T03-R10, R11).
  """

  alias Kiln.Store.Canonical

  @schema "session_projection/v1"
  @reducer_version "1"

  @type t :: %{optional(String.t()) => term()}

  @doc "The projection schema identifier."
  @spec schema() :: String.t()
  def schema, do: @schema

  @doc "The reducer version stamped into every projection it produces."
  @spec reducer_version() :: String.t()
  def reducer_version, do: @reducer_version

  @doc "Canonical SHA-256 digest of a projection."
  @spec digest(t()) :: String.t()
  def digest(projection), do: Canonical.digest(@schema, projection)

  @doc """
  Stamp the journal position and reducer version onto a reduced projection.

  Both the append transaction and the replay rebuild call this so their outputs
  are identical for the same journal prefix.
  """
  @spec stamp(t(), non_neg_integer(), non_neg_integer()) :: t()
  def stamp(projection, session_revision, last_sequence) do
    projection
    |> Map.put("schema", @schema)
    |> Map.put("reducer_version", @reducer_version)
    |> Map.put("session_revision", session_revision)
    |> Map.put("last_sequence", last_sequence)
  end
end
