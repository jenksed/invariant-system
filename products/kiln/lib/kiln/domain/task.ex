defmodule Kiln.Domain.Task do
  @moduledoc """
  The first accepted outcome and criteria inside a Session.
  """

  alias Kiln.Domain.{Error, Id}

  @states [:in_progress, :satisfied, :abandoned]

  @enforce_keys [
    :id,
    :session_id,
    :statement,
    :criteria,
    :constraints,
    :exclusions,
    :state,
    :revision,
    :created_at
  ]
  defstruct [
    :id,
    :session_id,
    :statement,
    :criteria,
    :constraints,
    :exclusions,
    :state,
    :revision,
    :created_at
  ]

  @type state :: :in_progress | :satisfied | :abandoned

  @type t :: %__MODULE__{
          id: String.t(),
          session_id: String.t(),
          statement: String.t(),
          criteria: [String.t()],
          constraints: [String.t()],
          exclusions: [String.t()],
          state: state(),
          revision: non_neg_integer(),
          created_at: DateTime.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) do
    with :ok <- Id.validate(:task, Map.get(attrs, :id)),
         :ok <- Id.validate(:session, Map.get(attrs, :session_id)),
         {:ok, statement} <- nonempty_string(attrs, :statement),
         {:ok, criteria} <- nonempty_string_list(attrs, :criteria, minimum: 1),
         {:ok, constraints} <- nonempty_string_list(attrs, :constraints, minimum: 0),
         {:ok, exclusions} <- nonempty_string_list(attrs, :exclusions, minimum: 0),
         {:ok, created_at} <- datetime(attrs, :created_at) do
      {:ok,
       %__MODULE__{
         id: attrs.id,
         session_id: attrs.session_id,
         statement: statement,
         criteria: criteria,
         constraints: constraints,
         exclusions: exclusions,
         state: :in_progress,
         revision: 0,
         created_at: created_at
       }}
    end
  end

  def new(_attrs), do: {:error, Error.new(:invalid_attributes, "task attributes must be a map")}

  @spec states() :: [state()]
  def states, do: @states

  defp nonempty_string(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a non-empty string", field)}
    end
  end

  defp nonempty_string_list(attrs, field, minimum: minimum) do
    value = Map.get(attrs, field, [])

    if is_list(value) and length(value) >= minimum and
         Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_field, "field must be a list of non-empty strings", field)}
    end
  end

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
