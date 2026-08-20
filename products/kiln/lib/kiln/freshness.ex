defmodule Kiln.Freshness do
  @moduledoc """
  M4 — Authority and Freshness modeled as separate dimensions.

  AUTHORITY answers: Is this work governed by Invariant?
  FRESHNESS answers: Is this presentation current?

  These are independent axes. A valid UI state is e.g.:
    AUTHORITY=GOVERNED  FRESHNESS=STALE
  meaning: "the known workflow is governed, but this presentation is
  not confirmed current."

  Authority state is derived from canonical projection. Freshness
  is derived from the hydration generation and canonical
  invalidation events.

  Architecture: Kiln.M4 (M4-A, lane M4).
  """

  @type authority :: :governed | :unknown
  @type freshness :: :live | :hydrating | :reconnecting | :stale | :degraded
  @type status :: %{required(:authority) => authority(), required(:freshness) => freshness()}

  @doc "Authority of a canonical projection."
  @spec authority(any()) :: authority()
  def authority(%{nodes: [_ | _]}), do: :governed
  def authority(_), do: :unknown

  @doc "Freshness derived from the hydration lifecycle."
  @spec freshness(:live | :hydrating | :reconnecting | :stale | :degraded) :: freshness()
  def freshness(state) when state in [:live, :hydrating, :reconnecting, :stale, :degraded], do: state

  @doc "Combined status."
  @spec status(any(), freshness()) :: status()
  def status(projection, freshness_state) do
    %{authority: authority(projection), freshness: freshness(freshness_state)}
  end

  @doc "True iff a stale presentation is being shown."
  @spec stale?(status()) :: boolean()
  def stale?(%{freshness: f}), do: f in [:stale, :degraded]
  def stale?(_), do: false

  @doc "True iff the work is currently governed."
  @spec governed?(status()) :: boolean()
  def governed?(%{authority: :governed}), do: true
  def governed?(_), do: false
end
