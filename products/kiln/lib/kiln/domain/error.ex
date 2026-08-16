defmodule Kiln.Domain.Error do
  @moduledoc """
  Stable validation error returned by the pure first-month domain layer.
  """

  @enforce_keys [:code, :message]
  defstruct [:code, :field, :message, details: %{}]

  @type t :: %__MODULE__{
          code: atom(),
          field: atom() | nil,
          message: String.t(),
          details: map()
        }

  @spec new(atom(), String.t(), atom() | nil, map()) :: t()
  def new(code, message, field \\ nil, details \\ %{})
      when is_atom(code) and is_binary(message) and (is_atom(field) or is_nil(field)) and
             is_map(details) do
    %__MODULE__{code: code, field: field, message: message, details: details}
  end
end
