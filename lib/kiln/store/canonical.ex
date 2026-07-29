defmodule Kiln.Store.Canonical do
  @moduledoc """
  Canonical UTF-8 JSON encoding and digests for journal payloads and results.

  Object keys are emitted in sorted order with no insignificant whitespace, so
  the same logical value always produces the same bytes and the same SHA-256
  digest. Values are limited to JSON scalars, lists, and string-keyed maps;
  anything else raises, because domain payloads must be bounded plain data.
  """

  @doc "Encode `term` as canonical JSON text."
  @spec encode(term()) :: String.t()
  def encode(term), do: IO.iodata_to_binary(encode_value(term))

  @doc """
  SHA-256 hex digest over the canonical payload bytes bound to `schema`.

  The schema identifier is folded in so two payloads that encode identically
  under different schemas still receive distinct digests.
  """
  @spec digest(String.t(), term()) :: String.t()
  def digest(schema, term) when is_binary(schema) do
    :sha256
    |> :crypto.hash([schema, "\n", encode(term)])
    |> Base.encode16(case: :lower)
  end

  defp encode_value(nil), do: "null"
  defp encode_value(value) when is_boolean(value), do: JSON.encode!(value)
  defp encode_value(value) when is_integer(value), do: Integer.to_string(value)
  defp encode_value(value) when is_binary(value), do: JSON.encode!(value)

  defp encode_value(value) when is_list(value) do
    ["[", value |> Enum.map(&encode_value/1) |> Enum.intersperse(","), "]"]
  end

  defp encode_value(value) when is_map(value) do
    pairs =
      value
      |> Enum.map(fn {k, v} -> {to_key(k), v} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> [JSON.encode!(k), ":", encode_value(v)] end)
      |> Enum.intersperse(",")

    ["{", pairs, "}"]
  end

  defp encode_value(other) do
    raise ArgumentError, "canonical JSON does not accept #{inspect(other)}"
  end

  defp to_key(key) when is_binary(key), do: key
  defp to_key(key) when is_atom(key), do: Atom.to_string(key)
end
