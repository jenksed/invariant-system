defmodule Kiln.Conformance.Provider do
  @moduledoc """
  Behaviour required of the future MiniMax adapter and deterministic fake.

  No implementation is provided by Prompt 6-A. A module implementing this
  behaviour cannot be treated as authorized until Prompt 8-A names its scope.
  """

  @type request :: map()
  @type event :: map()
  @type result :: map()
  @type reason :: map() | atom()

  @callback stream(request(), (event() -> :ok)) :: {:ok, result()} | {:error, reason()}
  @callback cancel(term()) :: :ok | {:error, reason()}
end
