defmodule Kiln.Store.Error do
  @moduledoc """
  Stable error returned by the first-month SQLite state store.

  The `class` distinguishes the failure kinds required by P1-S01-T02-R15 so a
  caller can react without parsing messages. It never carries secrets, source,
  or connection handles.
  """

  @classes [
    :busy,
    :integrity,
    :migration,
    :future_version,
    :revision,
    :idempotency_conflict,
    :precondition,
    :io,
    :unknown
  ]

  @enforce_keys [:class, :code, :message]
  defstruct [:class, :code, :message, details: %{}]

  @type class ::
          :busy
          | :integrity
          | :migration
          | :future_version
          | :revision
          | :idempotency_conflict
          | :precondition
          | :io
          | :unknown

  @type t :: %__MODULE__{
          class: class(),
          code: atom(),
          message: String.t(),
          details: map()
        }

  @doc "The complete accepted store-error class set."
  @spec classes() :: [class()]
  def classes, do: @classes

  @spec new(class(), atom(), String.t(), map()) :: t()
  def new(class, code, message, details \\ %{})
      when class in @classes and is_atom(code) and is_binary(message) and is_map(details) do
    %__MODULE__{class: class, code: code, message: message, details: details}
  end
end
