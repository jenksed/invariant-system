defmodule Kiln do
  @moduledoc """
  The public domain boundary for the Kiln coding harness.

  Interfaces such as the CLI and future Phoenix application must call explicit
  domain functions rather than manipulating runtime processes directly.
  """

  @doc "Returns the current development version."
  @spec version() :: String.t()
  def version, do: "0.1.0-dev"
end
