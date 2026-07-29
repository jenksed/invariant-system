defmodule Kiln.Store.Uuid do
  @moduledoc """
  Minimal UUIDv7 generator for opaque journal entry identifiers.

  UUIDv7 embeds a millisecond timestamp followed by random bits, so ids sort in
  roughly creation order while staying opaque. Uniqueness is still enforced by
  the store's unique constraints; this only supplies the opaque value.
  """

  @doc "Generate a lowercase, dash-formatted UUIDv7 string."
  @spec v7() :: String.t()
  def v7 do
    ms = System.system_time(:millisecond)
    <<rand_a::12, rand_b::62, _::6>> = :crypto.strong_rand_bytes(10)
    format(<<ms::48, 7::4, rand_a::12, 2::2, rand_b::62>>)
  end

  defp format(<<a::32, b::16, c::16, d::16, e::48>>) do
    [a, b, c, d, e]
    |> Enum.zip([8, 4, 4, 4, 12])
    |> Enum.map_join("-", fn {value, width} ->
      value |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(width, "0")
    end)
  end
end
