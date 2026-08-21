defmodule Kiln.RPC.Handlers.Graph do
  @moduledoc """
  Read-only graph projection over the canonical Session projection.

  This is a transport projection, not a second workflow authority. Every node
  and edge is derived from fields already present in `Workflow.query_session/1`.
  No planner relationship, scheduling claim, or inferred lifecycle identity is
  introduced here.

  The existing `Kiln.GraphProjection` remains the richer governed-envelope
  graph for M4 evidence chains. `graph.query` closes the production transport
  gap for the live Workbench by exposing the canonical Session/Task/Run graph
  and exact reference edges that are available from durable Session state.
  """

  alias Kiln.Domain.Error, as: DomainError
  alias Kiln.Workflow

  @schema "kiln/session-graph/v1"

  @spec handle(String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, %{required(:code) => atom()}}
  def handle("graph.query", params, _opts) when is_map(params) do
    with {:ok, session_id} <- require_string(params, "session_id"),
         {:ok, query} <- normalize_query(Workflow.query_session(session_id)) do
      {:ok, build_graph(query)}
    end
  end

  def handle(_method, _params, _opts), do: {:error, %{code: :E_UNKNOWN_METHOD}}

  defp normalize_query({:ok, :empty}) do
    {:error, %{code: :E_SESSION_NOT_FOUND, reason: "no canonical Session exists"}}
  end

  defp normalize_query({:ok, query}) when is_map(query), do: {:ok, query}

  defp normalize_query(
         {:error,
          %DomainError{code: code, message: message, field: field, details: details}}
       ) do
    {:error, %{code: code, reason: message, field: field, details: details}}
  end

  defp normalize_query({:error, %{code: _} = err}), do: {:error, err}

  defp normalize_query({:error, reason}),
    do: {:error, %{code: :E_GRAPH_QUERY_FAILED, reason: reason}}

  defp build_graph(query) do
    projection = query.projection
    session = map_or_empty(projection["session"])
    task = map_or_empty(projection["task"])
    run = map_or_empty(projection["run"])
    references = map_or_empty(projection["references"])
    pending = map_or_empty(projection["pending_decision"])

    nodes =
      []
      |> add_entity_node("Session", session, query.projection_digest, ["state"])
      |> add_entity_node("Task", task, query.projection_digest, ["state"])
      |> add_entity_node("Run", run, query.projection_digest, ["state"])
      |> add_pending_decision_node(pending, query.projection_digest)
      |> add_reference_nodes(references)
      |> Enum.sort_by(& &1.id)

    node_ids = MapSet.new(nodes, & &1.id)

    edges =
      []
      |> maybe_edge(session["id"], task["id"], "CONTAINS", "projection.task", node_ids)
      |> maybe_edge(task["id"], run["id"], "HAS_RUN", "projection.run", node_ids)
      |> maybe_edge(
        run["id"],
        pending["id"],
        "AWAITS_DECISION",
        "projection.pending_decision",
        node_ids
      )
      |> add_reference_edges(run["id"], references, node_ids)
      |> Enum.sort_by(& &1.id)

    %{
      "schema" => @schema,
      "session_id" => query.session_id,
      "revision" => projection["session_revision"] || 0,
      "projection_digest" => query.projection_digest,
      "source" => Atom.to_string(query.source),
      "orphaned" => query.orphaned,
      "nodes" => nodes,
      "edges" => edges
    }
  end

  defp add_entity_node(nodes, kind, entity, digest, metadata_keys) do
    case entity["id"] do
      id when is_binary(id) and byte_size(id) > 0 ->
        metadata = Map.take(entity, metadata_keys)

        [
          %{
            "id" => id,
            "kind" => kind,
            "canonical_digest" => digest,
            "metadata" => metadata
          }
          | nodes
        ]

      _ ->
        nodes
    end
  end

  defp add_pending_decision_node(nodes, pending, digest) do
    case pending["id"] do
      id when is_binary(id) and byte_size(id) > 0 ->
        metadata =
          Map.take(pending, [
            "subject_kind",
            "subject_id",
            "subject_revision",
            "permitted_responses"
          ])

        [
          %{
            "id" => id,
            "kind" => "Decision",
            "canonical_digest" => digest,
            "metadata" => metadata
          }
          | nodes
        ]

      _ ->
        nodes
    end
  end

  defp add_reference_nodes(nodes, references) do
    decision_envelope = map_or_empty(references["decision_envelope"])

    [
      {"PlanRef", map_or_empty(decision_envelope["plan_ref"])},
      {"PatchRef", map_or_empty(decision_envelope["patch_ref"])},
      {"ReviewRef", map_or_empty(decision_envelope["review_ref"])}
    ]
    |> Enum.reduce(nodes, fn {kind, ref}, acc ->
      case {ref["id"], ref["digest"]} do
        {id, digest} when is_binary(id) and is_binary(digest) ->
          [
            %{
              "id" => id,
              "kind" => kind,
              "canonical_digest" => digest,
              "metadata" => %{}
            }
            | acc
          ]

        _ ->
          acc
      end
    end)
  end

  defp add_reference_edges(edges, run_id, references, node_ids) do
    decision_envelope = map_or_empty(references["decision_envelope"])

    [
      {
        map_or_empty(decision_envelope["plan_ref"])["id"],
        "REFERENCES_PLAN",
        "references.decision_envelope.plan_ref"
      },
      {
        map_or_empty(decision_envelope["patch_ref"])["id"],
        "REFERENCES_PATCH",
        "references.decision_envelope.patch_ref"
      },
      {
        map_or_empty(decision_envelope["review_ref"])["id"],
        "REFERENCES_REVIEW",
        "references.decision_envelope.review_ref"
      }
    ]
    |> Enum.reduce(edges, fn {to_id, kind, basis}, acc ->
      maybe_edge(acc, run_id, to_id, kind, basis, node_ids)
    end)
  end

  defp maybe_edge(edges, from_id, to_id, kind, basis, node_ids)
       when is_binary(from_id) and is_binary(to_id) do
    if MapSet.member?(node_ids, from_id) and MapSet.member?(node_ids, to_id) do
      [
        %{
          "id" => "edg_#{kind}_#{from_id}_#{to_id}",
          "kind" => kind,
          "from" => from_id,
          "to" => to_id,
          "canonical_basis" => basis,
          "proposed" => false
        }
        | edges
      ]
    else
      edges
    end
  end

  defp maybe_edge(edges, _from_id, _to_id, _kind, _basis, _node_ids), do: edges

  defp map_or_empty(value) when is_map(value), do: value
  defp map_or_empty(_), do: %{}

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error,
         %{code: :E_INVALID_FIELD, reason: "#{key} must be a non-empty string", field: key}}
    end
  end
end
