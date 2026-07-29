defmodule Kiln.Store.Canonical do
  @moduledoc """
  Canonical UTF-8 JSON encoding and digests for journal payloads and results.

  Object keys are emitted in sorted order with no insignificant whitespace, so
  the same logical value always produces the same bytes and the same SHA-256
  digest. Values are limited to JSON scalars, lists, and atom- or string-keyed
  maps whose keys remain unique after atom keys are normalized to strings;
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
  defp encode_value(value) when is_float(value), do: JSON.encode!(value)
  defp encode_value(value) when is_binary(value), do: JSON.encode!(value)

  defp encode_value(value) when is_list(value) do
    ["[", value |> Enum.map(&encode_value/1) |> Enum.intersperse(","), "]"]
  end

  defp encode_value(value) when is_map(value) do
    pairs = Enum.map(value, fn {key, child} -> {to_key(key), child} end)

    case duplicate_key(pairs) do
      nil ->
        pairs
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn {key, child} -> [JSON.encode!(key), ":", encode_value(child)] end)
        |> Enum.intersperse(",")
        |> then(&["{", &1, "}"])

      key ->
        raise ArgumentError,
              "canonical JSON contains duplicate normalized key #{inspect(key)}"
    end
  end

  defp encode_value(other) do
    raise ArgumentError, "canonical JSON does not accept #{inspect(other)}"
  end

  defp duplicate_key(pairs) do
    pairs
    |> Enum.frequencies_by(&elem(&1, 0))
    |> Enum.find_value(fn
      {key, count} when count > 1 -> key
      _entry -> nil
    end)
  end

  defp to_key(key) when is_binary(key), do: key
  defp to_key(key) when is_atom(key), do: Atom.to_string(key)

  defp to_key(key) do
    raise ArgumentError, "canonical JSON keys must be atoms or strings, got: #{inspect(key)}"
  end
end
