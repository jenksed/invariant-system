defmodule Kiln.M0Currentness do
  @moduledoc """
  Shared bounded currentness check for the M0 governed loop.

  Extracted from the M8 IMPLEMENTER dispatch path so the M9
  REVIEWER dispatch path can apply the same canonical check at its
  boundary, without creating CLI → Worker coupling merely to reuse a
  private helper. The semantics — 168-hour window between
  `derived_at` and `valid_until` against the bounded failure
  vocabulary — are unchanged from the IMPLEMENTER boundary.

  This is DETERMINISTIC IMPLEMENTATION DISCRETION: the M9 work
  package (E2) already requires the Reviewer to be "current
  QUALIFIED eligibility". The current implementation revalidates at
  the IMPLEMENTER boundary but not at the REVIEWER boundary. This
  module is the single source of truth so the two boundaries cannot
  drift in incompatible ways.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  alias Kiln.Store.Canonical

  @spec within_currentness_window?(map()) :: boolean()
  def within_currentness_window?(eligibility) when is_map(eligibility) do
    case {eligibility["derived_at"], eligibility["valid_until"]} do
      {derived_at, valid_until}
      when is_binary(derived_at) and is_binary(valid_until) ->
        with {:ok, valid_until_dt} <- safe_parse_iso8601(valid_until),
             {:ok, derived_at_dt} <- safe_parse_iso8601(derived_at) do
          now = DateTime.utc_now()

          cond do
            DateTime.compare(now, derived_at_dt) == :lt -> false
            DateTime.compare(now, valid_until_dt) == :gt -> false
            true -> DateTime.diff(now, derived_at_dt, :second) <= 168 * 3600
          end
        else
          _ -> false
        end

      _ ->
        false
    end
  end

  def within_currentness_window?(_), do: false

  @spec stale_error(map()) :: {:error, %{code: :E_QUALIFICATION_NOT_CURRENT, reason: String.t()}}
  def stale_error(eligibility) when is_map(eligibility) do
    {:error,
     %{
       code: :E_QUALIFICATION_NOT_CURRENT,
       reason:
         "eligibility is stale at dispatch: derived_at=" <>
           inspect(eligibility["derived_at"]) <>
           ", valid_until=" <> inspect(eligibility["valid_until"])
     }}
  end

  # Private helpers — non-raising parser; invalid timestamps fail closed
  # (return :error) so the canonical 168h check can never raise on
  # malformed reviewer eligibility at the M9 dispatch boundary.

  defp safe_parse_iso8601(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> {:ok, dt}
      _ -> :error
    end
  end
end