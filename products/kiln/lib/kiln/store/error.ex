defmodule Kiln.Store.Error do
  @moduledoc """
  Stable error returned by the first-month SQLite state store.

  The `class` distinguishes the failure kinds required by P1-S01-T02-R15 so a
  caller can react without parsing messages. It never carries secrets, source,
  or connection handles.

  The accepted T02 error class set is:

      :busy, :integrity, :migration, :future_version, :revision,
      :idempotency_conflict, :io, :unknown

  The `:precondition` class was added as a narrow T02 vocabulary extension
  by P1-S01-T04 (PR #40) to represent a transaction-level precondition
  rejection raised by `Kiln.Store.Journal.commit/4` (e.g. the
  first-month one-Session guard). It is the semantically correct result
  of an enforced durable invariant, not a generic failure, and gives
  Workflow callers a stable, typed signal without forcing the Store
  layer to leak Domain error types. The class is owned by the Store
  layer; callers consume it through `Kiln.Store.Error{}` and translate
  to their public vocabulary at their own boundary.
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
