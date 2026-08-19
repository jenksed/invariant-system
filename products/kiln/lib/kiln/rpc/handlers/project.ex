defmodule Kiln.RPC.Handlers.Project do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `project.open` and `project.list`.

  This handler is the entrypoint for the live Temper client. It opens
  a repository at a known filesystem path, ensures a bounded Kiln
  `Kiln.Store.Connection` is registered, and returns a canonical
  WorkbenchModel-shape projection:

      %{
        "status"             => "opened",
        "path"               => path,
        "kiln_home"          => kiln_home,
        "session_id"         => session_id | nil,
        "canonical_session_revision" => integer | nil,
        "orphaned"           => boolean | nil,
        "unknowns"           => [String.t()] | nil,
        "scope_table_version"=> "kiln/rpc/scope-table/v1"
      }

  Per the WP-09 contract freeze (§2, §9):
  * `project.list` returns the bounded project inventory known to Kiln.
    Current implementation returns an empty list — there is no
    project-registry module, and inventing one is out of WP-09 scope.
    The shape is frozen so Temper can render the empty state without
    a contract change.
  * `project.open` is the only acceptance-required "open repo" path.
    It validates `path`, ensures the bounded Store is started, and
    returns canonical state for the active session (if any) by calling
    `Kiln.Workflow.query_session/1`.

  Scope (router.ex scope table):
    project.list → orchestration:read
    project.open → orchestration:operate

  Bounded error codes (router.ex P5):
    E_BODY_READ_FAILED, E_MALFORMED_REQUEST — service.ex
    E_SCOPE_INSUFFICIENT, E_UNKNOWN_METHOD, E_NOT_IMPLEMENTED — router.ex
    E_MISSING_FIELDS, E_INVALID_FIELD, E_PROJECT_INVALID_PATH,
    E_PROJECT_NOT_FOUND, E_STORE_UNAVAILABLE — this module
  """

  alias Kiln.Domain.{Error, as: DomainError}
  alias Kiln.Restart
  alias Kiln.Store

  @doc "Dispatch a Project-family method."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()}
          | {:error, %{required(:code) => atom(), required(:reason) => term()}}
  def handle(method, params, opts) when is_map(params) and is_list(opts) do
    case method do
      "project.list" -> project_list(params)
      "project.open" -> project_open(params, opts)
      _ -> {:error, %{code: :E_UNKNOWN_METHOD, method: method}}
    end
  end

  # -- project.list --
  #
  # Truthful empty list. No project-registry module exists in WP-09
  # scope; the contract freeze (§9) requires this shape so Temper
  # can render an empty workbench without inventing state.
  defp project_list(_params) do
    {:ok,
     %{
       "projects" => [],
       "scope_table_version" => "kiln/rpc/scope-table/v1"
     }}
  end

  # -- project.open --
  #
  # Validates the path, ensures the bounded Store is registered, and
  # returns canonical state for any active Session bound to this
  # repository. The canonical state is derived from the journal
  # (sole authority) via `Kiln.Restart.reconstruct/1` — NEVER from
  # local Temper caches.
  defp project_open(params, _opts) do
    with {:ok, path} <- require_string(params, "path"),
         :ok <- validate_path(path),
         {:ok, kiln_home} <- derive_kiln_home(path),
         :ok <- ensure_store_or_return(kiln_home),
         {:ok, reconstruction} <- safe_reconstruct(kiln_home) do
      {:ok,
       %{
         "status" => "opened",
         "path" => path,
         "kiln_home" => kiln_home,
         "session_id" => reconstruction[:session_id],
         "canonical_session_revision" => reconstruction[:revision],
         "orphaned" => reconstruction[:orphaned],
         "unknowns" => reconstruction[:unknowns],
         "scope_table_version" => "kiln/rpc/scope-table/v1"
       }}
    end
  end

  # -- helpers --

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error,
         %{
           code: :E_MISSING_FIELDS,
           reason: "missing required field: #{key}",
           fields: [key]
         }}
    end
  end

  defp validate_path(path) do
    cond do
      not File.exists?(path) ->
        {:error,
         %{code: :E_PROJECT_NOT_FOUND, reason: "path does not exist: #{path}"}}

      not File.regular?(path) ->
        {:error,
         %{code: :E_PROJECT_INVALID_PATH, reason: "path is not a regular file or directory: #{path}"}}

      true ->
        :ok
    end
  end

  # The kiln_home convention is `<repo>/.kiln/` (matches the CLI's
  # `--kiln-home` default). If absent the Store is not yet started;
  # we return canonical `E_STORE_UNAVAILABLE` so the caller knows
  # to start the bounded Store via `mix invariant serve --state-path`.
  defp derive_kiln_home(path) do
    home = Path.join(path, ".kiln")
    {:ok, home}
  end

  defp ensure_store_or_return(kiln_home) do
    if Process.whereis(Kiln.Store.Connection) do
      :ok
    else
      state_path = Path.join(kiln_home, "state.sqlite3")

      if File.regular?(state_path) do
        case Store.start_link(
               path: state_path,
               name: Kiln.Store.Connection,
               store_id: "rpc_project_#{System.unique_integer([:positive])}"
             ) do
          {:ok, _pid} -> :ok
          {:error, reason} -> {:error, store_unavailable(reason)}
        end
      else
        {:error,
         %{
           code: :E_STORE_UNAVAILABLE,
           reason: "Kiln.Store.Connection not registered; start the daemon with --state-path=#{kiln_home}"
         }}
      end
    end
  end

  defp store_unavailable(reason) do
    %{code: :E_STORE_UNAVAILABLE, reason: inspect(reason)}
  end

  # Wraps `Kiln.Restart.reconstruct/1` so a missing journal returns
  # `:empty` (canonical, not an error) and a corrupt journal returns
  # the bounded error envelope. `:multiple_sessions` is reported as
  # canonical state (Temper decides how to render).
  defp safe_reconstruct(_kiln_home) do
    case Restart.reconstruct(:project_open) do
      :empty ->
        {:ok, %{session_id: nil, revision: nil, orphaned: nil, unknowns: []}}

      {:ok, reconstruction} when is_map(reconstruction) ->
        {:ok,
         %{
           session_id: Map.get(reconstruction, :session_id),
           revision: Map.get(reconstruction, :revision),
           orphaned: Map.get(reconstruction, :orphaned),
           unknowns: Map.get(reconstruction, :unknowns, [])
         }}

      {:error, %DomainError{code: code, message: message}} ->
        {:error, %{code: code, reason: message}}

      {:error, %{code: _} = err} ->
        {:error, err}

      {:error, reason} ->
        {:error, %{code: :E_DISPATCH_FAILED, reason: inspect(reason)}}

      :multiple_sessions ->
        {:ok,
         %{
           session_id: nil,
           revision: nil,
           orphaned: nil,
           unknowns: ["multiple_sessions_in_journal"]
         }}
    end
  end
end
