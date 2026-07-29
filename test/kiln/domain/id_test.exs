defmodule Kiln.Domain.IdTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.Id

  @entropy :binary.copy(<<0xAB>>, 16)
  @kinds [
    :project_observation,
    :session,
    :task,
    :run,
    :decision,
    :operation,
    :action,
    :idempotency
  ]

  test "generates deterministic opaque identifiers for every accepted kind" do
    entropy_source = fn 16 -> @entropy end

    identifiers =
      for kind <- @kinds, into: %{} do
        assert {:ok, identifier} = Id.generate(kind, entropy_source)
        assert Id.valid?(kind, identifier)
        {kind, identifier}
      end

    assert map_size(identifiers) == length(@kinds)
    assert MapSet.size(MapSet.new(Map.values(identifiers))) == length(@kinds)
  end

  test "rejects unsupported kinds and malformed entropy" do
    assert {:error, %{code: :unsupported_identifier_kind}} = Id.generate(:provider, fn 16 -> @entropy end)
    assert {:error, %{code: :invalid_entropy}} = Id.generate(:session, fn 16 -> <<1, 2>> end)
    refute Id.valid?(:session, "ses_not-hex")
  end
end
