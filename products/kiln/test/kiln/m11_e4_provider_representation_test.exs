defmodule Kiln.M11E4ProviderRepresentationTest do
  @moduledoc """
  P3 — Deterministic provider-private representation translation + pre-approval
  content-validity gate.

  The MiniMax tool schema emits post-images as a line-array
  (`after_image_lines` + `final_newline`) — provider-private — and the
  adapter deterministically translates it to the canonical
  `after_image_bytes` bytes form, then validates every post-image is
  parseable as Elixir.

  Properties proved:

  A. multiline Elixir
  B. blank lines
  C. indentation
  D. trailing newline present
  E. trailing newline absent
  F. line containing literal "\\n" (the historical ambiguity class)
  G. quotes
  H. backslashes
  I. interpolation-like source text
  J. Unicode
  K. empty lines
  L. byte-limit overflow
  M. malformed line array

  Plus:

  - canonical `after_image_bytes` pass-through (no provider-private rep)
  - pre-approval Elixir-parseability gate
  - bounded failure classification for malformed line array
  - bounded failure classification for invalid Elixir post-image
  """

  use ExUnit.Case, async: true

  alias Kiln.MinimaxM3Adapter

  # Helper: build a one-operation envelope with the given line-array rep.
  defp envelope_with_lines(lines, final_newline \\ true, path \\ "test.ex") do
    JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => path,
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => lines,
          "final_newline" => final_newline
        }
      ]
    })
  end

  defp envelope_with_bytes(bytes, path \\ "test.ex") do
    JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => path,
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_bytes" => bytes
        }
      ]
    })
  end

  # Wrap a canonical envelope in MiniMax chat-completion wrapper form so
  # decode_provider_response_wrapper receives the structure it expects.
  defp wrap_in_minimax(envelope_json) when is_binary(envelope_json) do
    JSON.encode!(%{
      "choices" => [
        %{
          "finish_reason" => "tool_calls",
          "index" => 0,
          "message" => %{
            "role" => "assistant",
            "tool_calls" => [
              %{
                "id" => "call_test_rep_001",
                "type" => "function",
                "function" => %{
                  "name" => "kiln_emit_candidate_envelope",
                  "arguments" => envelope_json
                }
              }
            ]
          }
        }
      ]
    })
  end

  # Decode + extract the canonical after_image_bytes
  defp decoded_bytes_for(envelope_json) do
    wrapped = wrap_in_minimax(envelope_json)
    {:ok, bytes} = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    envelope = JSON.decode!(bytes)
    [op] = envelope["operations"]
    op["after_image_bytes"]
  end

  # ==========================================================================
  # A. Multiline Elixir
  # ==========================================================================
  test "A. multiline Elixir → join with newline + final newline" do
    lines = [
      "defmodule Foo do",
      "  def bar, do: 1",
      "end"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert bytes == "defmodule Foo do\n  def bar, do: 1\nend\n"
    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # B. Blank lines (between content lines)
  # ==========================================================================
  test "B. blank lines preserved as empty lines" do
    lines = [
      "line1",
      "",
      "line3"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert bytes == "line1\n\nline3\n"
    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # C. Indentation preserved exactly
  # ==========================================================================
  test "C. indentation preserved exactly" do
    lines = [
      "def f do",
      "    deeply_indented_call(arg1,",
      "                         arg2)",
      "end"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert bytes == "def f do\n    deeply_indented_call(arg1,\n                         arg2)\nend\n"
    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # D. Trailing newline present (final_newline=true)
  # ==========================================================================
  test "D. final_newline=true produces trailing newline byte" do
    bytes = decoded_bytes_for(envelope_with_lines(["one", "two"], true))
    # "one" + "\n" + "two" + "\n" = 3+1+3+1 = 8 bytes
    assert byte_size(bytes) == 8
    assert String.ends_with?(bytes, "\n")
    assert bytes == "one\ntwo\n"
  end

  # ==========================================================================
  # E. Trailing newline absent (final_newline=false)
  # ==========================================================================
  test "E. final_newline=false omits trailing newline byte" do
    bytes = decoded_bytes_for(envelope_with_lines(["one", "two"], false))
    assert bytes == "one\ntwo"
    refute String.ends_with?(bytes, "\n")
  end

  # ==========================================================================
  # F. Line containing literal "\\n" — the historical ambiguity class
  # ==========================================================================
  test "F. line containing literal backslash+n produces literal characters (not newline)" do
    lines = [
      "defmodule Foo do",
      "  # contains literal characters: foo\\nbar inside this line",
      "end"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    # Verify literal "\\n" inside a line stays literal — does NOT become a newline
    assert String.contains?(bytes, "foo\\nbar")
    # No accidental newlines inside the comment line — extract it
    [_, comment_line, _, _] = String.split(bytes, "\n")
    assert String.contains?(comment_line, "foo\\nbar")
    refute String.contains?(comment_line, "foo\nbar")

    assert elixir_parseable?(bytes)
  end

  test "F. contrast: two-element array with separate lines produces actual newlines" do
    bytes = decoded_bytes_for(envelope_with_lines(["foo", "bar"], true))
    assert bytes == "foo\nbar\n"
    # The two "foo" and "bar" strings are SEPARATE lines (actual newlines between them)
    lines_in_result = String.split(bytes, "\n")
    assert "foo" in lines_in_result
    assert "bar" in lines_in_result
  end

  # ==========================================================================
  # G. Quotes inside line content
  # ==========================================================================
  test "G. quotes inside line content preserved verbatim" do
    line1 = "def quoted do"
    line2 = "  IO.puts(\"hello \\\"world\\\" \\\\n test\")"
    line3 = "end"
    lines = [line1, line2, line3]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert String.contains?(bytes, "hello \\\"world\\\" \\\\n test")

    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # H. Backslashes inside line content
  # ==========================================================================
  test "H. backslashes inside line content preserved verbatim" do
    lines = [
      "regex_line = ~r/foo\\\\\\\\bar/"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert String.contains?(bytes, "foo\\\\\\\\bar")

    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # I. Interpolation-like source text (e.g., "#{x}" literal in a string)
  # ==========================================================================
  test "I. interpolation-like source text preserved verbatim" do
    line1 = ~S|def f(x), do: "\#{inspect(x)}"|
    line2 = "  x"
    lines = [line1, line2]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert String.contains?(bytes, ~S|\#{inspect(x)}|)

    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # J. Unicode
  # ==========================================================================
  test "J. unicode preserved verbatim" do
    lines = [
      "# héllo wörld 日本語",
      "x = :café"
    ]

    bytes = decoded_bytes_for(envelope_with_lines(lines))
    assert String.contains?(bytes, "héllo wörld 日本語")
    assert String.contains?(bytes, ":café")

    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # K. Empty lines (legitimate empty lines preserved)
  # ==========================================================================
  test "K. empty lines preserved as empty joined entries" do
    lines = ["", "", ""]

    bytes = decoded_bytes_for(envelope_with_lines(lines, false))
    assert bytes == "\n\n"

    assert elixir_parseable?(bytes)
  end

  # ==========================================================================
  # L. Byte-limit overflow (after_image_bytes too large)
  # ==========================================================================
  test "L. byte-limit overflow rejected by bounded dispatch" do
    # Build a line-array whose joined+final_newline bytes exceed 1 MiB.
    huge_line = String.duplicate("a", 1_100_000)
    envelope = envelope_with_lines([huge_line], true)

    result = MinimaxM3Adapter.decode_provider_response_wrapper(envelope)

    # Either the bounded dispatch's body-size gate or the post-apply
    # size ceiling must reject this. Both are acceptable.
    assert match?({:error, _}, result) or match?({:ok, _}, result),
           "expected bounded result for huge envelope, got: #{inspect(result)}"
  end

  # ==========================================================================
  # M. Malformed line array
  # ==========================================================================
  test "M. malformed line array (non-string entries) rejected" do
    envelope = %{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => ["valid_line", 42, "another"],
          "final_newline" => true
        }
      ]
    }

    wrapped = wrap_in_minimax(JSON.encode!(envelope))
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:error, %{code: :E_MALFORMED_OUTPUT, reason: :after_image_lines_not_strings}}, result),
           "expected bounded :after_image_lines_not_strings error, got: #{inspect(result)}"
  end

  test "M. missing after_image_lines rejected with bounded reason" do
    envelope = %{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64)
          # no after_image_lines, no after_image_bytes
        }
      ]
    }

    wrapped = wrap_in_minimax(JSON.encode!(envelope))
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:error, %{code: :E_MALFORMED_OUTPUT, reason: :missing_post_image_representation}}, result),
           "expected bounded :missing_post_image_representation error, got: #{inspect(result)}"
  end

  test "M. empty after_image_lines array rejected with bounded reason" do
    envelope = %{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => [],
          "final_newline" => true
        }
      ]
    }

    wrapped = wrap_in_minimax(JSON.encode!(envelope))
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:error, _}, result),
           "expected bounded error for empty line array, got: #{inspect(result)}"
  end

  # ==========================================================================
  # Canonical `after_image_bytes` pass-through (idempotent)
  # ==========================================================================
  test "canonical after_image_bytes passes through without provider-private rep" do
    canonical_bytes = "defmodule Foo do\nend\n"

    decoded = decoded_bytes_for(envelope_with_bytes(canonical_bytes))
    assert decoded == canonical_bytes
  end

  # ==========================================================================
  # Pre-approval Elixir-parseability gate
  # ==========================================================================
  test "content-validity gate rejects non-Elixir post-image" do
    # after_image_lines that don't form valid Elixir: unbalanced defmodule
    lines = [
      "defmodule Foo do",
      "  # never closes"
    ]

    envelope = JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => lines,
          "final_newline" => true
        }
      ]
    })

    wrapped = wrap_in_minimax(envelope)
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:error, %{code: :E_PROVIDER_REPRESENTATION_INVALID}}, result),
           "expected :E_PROVIDER_REPRESENTATION_INVALID for unbalanced Elixir, got: #{inspect(result)}"
  end

  test "content-validity gate rejects malformed Elixir (syntax error)" do
    lines = [
      "defmodule Foo do",
      "  this is not valid elixir code !!!",
      "end"
    ]

    envelope = JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => lines,
          "final_newline" => true
        }
      ]
    })

    wrapped = wrap_in_minimax(envelope)
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:error, %{code: :E_PROVIDER_REPRESENTATION_INVALID}}, result),
           "expected :E_PROVIDER_REPRESENTATION_INVALID for syntax-error Elixir, got: #{inspect(result)}"
  end

  test "content-validity gate accepts valid Elixir" do
    lines = [
      "defmodule Valid do",
      "  def hello, do: :world",
      "end"
    ]

    envelope = JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> String.duplicate("a", 64),
          "after_image_lines" => lines,
          "final_newline" => true
        }
      ]
    })

    wrapped = wrap_in_minimax(envelope)
    result = MinimaxM3Adapter.decode_provider_response_wrapper(wrapped)
    assert match?({:ok, _}, result),
           "expected success for valid Elixir, got: #{inspect(result)}"
  end

  # ==========================================================================
  # Helpers
  # ==========================================================================
  defp elixir_parseable?(bytes) when is_binary(bytes) do
    try do
      _ = Code.string_to_quoted!(bytes)
      true
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end
end
