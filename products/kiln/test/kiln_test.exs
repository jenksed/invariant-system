defmodule KilnTest do
  use ExUnit.Case, async: true

  test "exposes the development version" do
    assert Kiln.version() == "0.1.0-dev"
  end
end
