defmodule Kiln.Domain.Decision do
  @moduledoc """
  Durable shape for one exact pending local-user decision.
  """

  alias Kiln.Domain.{Error, Id}

  @subject_kinds [:objective, :criteria, :run, :operation, :patch, :completion, :reconciliation]
  @actors [:local_user]

  @enforce_keys [
    :id,
    :session_id,
    :run_id,
    :subject_kind,
    :subject_id,
    :subject_revision,
    :requested_actor,
    :permitted_responses,
    :resume_action,
    :requested_at
  ]
  defstruct [
    :id,
    :session_id,
    :run_id,
    :subject_kind,
    :subject_id,
    :subject_revision,
    :requested_actor,
    :permitted_responses,
    :resume_action,
    :requested_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          session_id: String.t(),
          run_id: String.t(),
          subject_kind: atom(),
          subject_id: String.t(),
          subject_revision: non_neg_integer(),
          requested_actor: :local_user,
          permitted_responses: [atom()],
          resume_action: atom(),
          requested_at: DateTime.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) do
    with :ok <- Id.validate(:decision, Map.get(attrs, :id)),
         :ok <- Id.validate(:session, Map.get(attrs, :session_id)),
         :ok <- Id.validate(:run, Map.get(attrs, :run_id)),
         :ok <- validate_subject_kind(Map.get(attrs, :subject_kind)),
         {:ok, subject_id} <- nonempty_string(attrs, :subject_id),
         :ok <- validate_revision(Map.get(attrs, :subject_revision)),
         :ok <- validate_actor(Map.get(attrs, :requested_actor)),
         {:ok, responses} <- responses(attrs),
         {:ok, resume_action} <- action_atom(attrs, :resume_action),
         {:ok, requested_at} <- datetime(attrs, :requested_at) do
      {:ok,
       %__MODULE__{
         id: attrs.id,
         session_id: attrs.session_id,
         run_id: attrs.run_id,
         subject_kind: attrs.subject_kind,
         subject_id: subject_id,
         subject_revision: attrs.subject_revision,
         requested_actor: attrs.requested_actor,
         permitted_responses: responses,
         resume_action: resume_action,
         requested_at: requested_at
       }}
    end
  end

  def new(_attrs),
    do: {:error, Error.new(:invalid_attributes, "decision attributes must be a map")}

  defp validate_subject_kind(kind) when kind in @subject_kinds, do: :ok

  defp validate_subject_kind(_kind) do
    {:error,
     Error.new(:invalid_subject_kind, "decision subject kind is not supported", :subject_kind)}
  end

  defp validate_revision(value) when is_integer(value) and value >= 0, do: :ok

  defp validate_revision(_value) do
    {:error,
     Error.new(
       :invalid_revision,
       "subject revision must be a non-negative integer",
       :subject_revision
     )}
  end

  defp validate_actor(actor) when actor in @actors, do: :ok

  defp validate_actor(_actor),
    do: {:error, Error.new(:invalid_actor, "decision actor is not permitted", :requested_actor)}

  defp responses(attrs) do
    value = Map.get(attrs, :permitted_responses)

    if is_list(value) and value != [] and Enum.all?(value, &is_atom/1) and
         length(value) == length(Enum.uniq(value)) do
      {:ok, value}
    else
      {:error,
       Error.new(
         :invalid_responses,
         "permitted responses must be a non-empty unique atom list",
         :permitted_responses
       )}
    end
  end

  defp action_atom(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_atom(value) -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be an atom", field)}
    end
  end

  defp nonempty_string(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a non-empty string", field)}
    end
  end

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
