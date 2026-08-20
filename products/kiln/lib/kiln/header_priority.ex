defmodule Kiln.HeaderPriority do
  @moduledoc """
  M4 — header/footer priority policy.

  The 80x24 snapshot earlier showed random truncation like
  "0 blo". That is not acceptable.

  Header priority (highest first):
    P0 — freshness/connectivity
    P0 — human attention (need you, your call)
    P0 — critical failure
    P1 — current-mode navigation hint
    P2 — aggregate counts
    P3 — secondary shortcuts

  At narrow widths, lower-priority items disappear (clean cut) rather
  than being squished into unreadability.

  Architecture: Kiln.M4 (M4-A, lane M4).
  """

  @p0 ["freshness", "your_call", "failure", "needs_you"]
  @p1 ["mode_hint"]
  @p2 ["counts"]
  @p3 ["secondary_shortcuts"]

  @doc "Render the header at the given width with priority-aware truncation."
  @spec render_header(map(), pos_integer()) :: String.t()
  def render_header(state, cols) do
    parts =
      [
        # P0 first; the list is in priority order so do_drop removes
        # from the END (lowest priority).
        freshness_part(state),
        your_call_part(state),
        failure_part(state),
        needs_you_part(state),
        mode_hint_part(state),
        counts_part(state)
      ] ++
        List.wrap(state[:secondary] || [])

    join_with_priority(parts, cols)
  end

  @doc "Render the footer at the given width with priority-aware truncation."
  @spec render_footer(map(), pos_integer()) :: String.t()
  def render_footer(state, cols) do
    parts =
      [
        failure_part(state)
      ] ++
        List.wrap(state[:shortcuts] || []) ++
        [counts_part(state)]

    join_with_priority(parts, cols)
  end

  # --- P0..P3 part builders, each returns nil when not applicable ---

  defp freshness_part(%{freshness: :stale}), do: "◌ STALE"
  defp freshness_part(%{freshness: :degraded}), do: "◌ DEGRADED"
  defp freshness_part(%{freshness: :hydrating}), do: "◌ HYDRATING"
  defp freshness_part(%{freshness: :reconnecting}), do: "◌ RECONNECTING"
  defp freshness_part(_), do: nil

  defp your_call_part(%{current_lifecycle_needs_you: true}), do: "★ YOUR CALL"
  defp your_call_part(_), do: nil

  defp failure_part(%{failed: n}) when n > 0, do: "✗ #{n} failed"
  defp failure_part(_), do: nil

  defp needs_you_part(%{needs_you: n}) when n > 0, do: "needs you: #{n}"
  defp needs_you_part(_), do: nil

  defp mode_hint_part(%{mode: mode}) when is_binary(mode), do: mode
  defp mode_hint_part(_), do: nil

  defp counts_part(%{counts: counts}) when is_map(counts) and counts != %{} do
    label = Enum.map_join(counts, " ", fn {k, v} -> "#{v} #{k}" end)
    if label == "", do: nil, else: label
  end
  defp counts_part(_), do: nil

  # --- join with priority-aware truncation ---

  defp join_with_priority(parts, cols) when is_list(parts) and cols > 0 do
    case join(parts, "  ", cols) do
      {:ok, text} -> text
      :too_long -> drop_lowest_priority(parts, "  ", cols)
    end
  end

  defp drop_lowest_priority(parts, sep, cols) do
    # Drop from the END (lowest priority). Keep the head (highest).
    do_drop(parts, sep, cols)
  end

  defp do_drop([], _sep, _cols), do: ""

  defp do_drop([only], _sep, cols), do: String.slice(only, 0, cols)

  defp do_drop(parts, sep, cols) do
    case join(parts, sep, cols) do
      {:ok, text} -> text
      :too_long -> do_drop(Enum.drop(parts, -1), sep, cols)
    end
  end

  defp join(parts, sep, cols) do
    text = Enum.join(parts, sep)
    if byte_size(text) <= cols, do: {:ok, text}, else: :too_long
  end
end
