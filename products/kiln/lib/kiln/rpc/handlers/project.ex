defmodule Kiln.RPC.Handlers.Project do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `project.open` and `project.list`.

  This handler is the entrypoint for the live Temper client. It opens
  a repository at a known filesystem path, ensures a bounded Kiln
  `Kiln.Store.Connection` is registered, and returns a canonical
  WorkbenchModel-shape projection:

      %{
        status: "opened",
        path: path,
        kiln_home: kiln_home,
        session_id: session_id | nil,
        canonical_session_revision: integer | nil,
        orphaned: boolean | nil,
        unknowns: [term()] | nil
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
    `Kiln.Restart.reconstruct/1` on the bounded Store connection.

  Scope (router.ex scope table):
    project.list → orchestration:read
    project.open → orchestration:operate

  Bounded error codes (router.ex P5):
    E_BODY_READ_FAILED, E_MALFORMED_REQUEST — service.ex
    E_SCOPE_INSUFFICIENT, E_UNKNOWN_METHOD, E_NOT_IMPLEMENTED — router.ex
    E_MISSING_FIELDS, E_INVALID_FIELD, E_PROJECT_INVALID_PATH,
    E_PROJECT_NOT_FOUND, E_STORE_UNAVAILABLE, E_MULTIPLE_SESSIONS,
    E_JOURNAL_BLOCKED — this module
  """

  alias Kiln.Restart

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
  # scope; the contract freeze requires this shape so Temper can render
  # an empty workbench without inventing state.
  defp project_list(_params) do
    {:ok, %{projects: []}}
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
         :ok <- require_store_registered(),
         {:ok, reconstruction} <- safe_reconstruct() do
      {:ok,
       %{
         status: "opened",
         path: path,
         kiln_home: kiln_home,
         session_id: Map.get(reconstruction, :session_id),
         canonical_session_revision: Map.get(reconstruction, :session_revision),
         orphaned: Map.get(reconstruction, :orphaned),
         unknowns: Map.get(reconstruction, :unknowns, [])
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

  # The bounded Store connection is owned by the daemon supervisor
  # (started via `mix invariant serve --state-path …` per WP-08 Lane 1).
  # The RPC layer MUST treat Store registration as a precondition. If
  # the Store is not registered, we return E_STORE_UNAVAILABLE — the
  # operator restarts the daemon with the correct --state-path. We
  # never start a second Store from inside an RPC handler because
  # that would create a parallel authoritative surface and violate
  # the bounded single-writer assumption.
  defp require_store_registered do
    if Process.whereis(Kiln.Store.Connection) do
      :ok
    else
      {:error,
       %{
         code: :E_STORE_UNAVAILABLE,
         reason: "Kiln.Store.Connection not registered; restart daemon with --state-path=<dir>"
       }}
    end
  end

  # Wraps `Kiln.Restart.reconstruct/1` against the bounded Store
  # connection. Per the @spec at lib/kiln/restart.ex:38-42, the return
  # shape is exactly one of:
  #
  #   {:ok, :empty}
  #   {:ok, %{session_id, session_revision, orphaned, projection, ...}}
  #   {:error, %{code: :multiple_sessions, detail: %{count, sessions}}}
  #   {:error, %{session_id, block}}   # journal blocked
  #
  # We translate each into the bounded WorkbenchModel-shape projection
  # Temper renders. We do NOT invent fields.
  defp safe_reconstruct do
    conn = Process.whereis(Kiln.Store.Connection)

    if is_nil(conn) do
      {:error, %{code: :E_STORE_UNAVAILABLE, reason: "Kiln.Store.Connection not registered"}}
    else
      case Restart.reconstruct(conn) do
        {:ok, :empty} ->
          {:ok, %{session_id: nil, session_revision: nil, orphaned: nil, unknowns: []}}

        {:ok, reconstruction} when is_map(reconstruction) ->
          unknowns =
            case Map.get(reconstruction, :projection) do
              %{} = proj -> Map.get(proj, "unknowns", [])
              _ -> []
            end

          {:ok,
           %{
             session_id: Map.get(reconstruction, :session_id),
             session_revision: Map.get(reconstruction, :session_revision),
             orphaned: Map.get(reconstruction, :orphaned),
             unknowns: unknowns
           }}

        {:error, %{code: :multiple_sessions} = err} ->
          # Multiple durable Sessions in the journal — surface as a
          # bounded error rather than inventing a canonical projection.
          {:error, Map.put(err, :reason, "multiple durable sessions in journal")}

        {:error, %{session_id: sid, block: block}} ->
          # Journal was incomplete or corrupt; reconstruction blocked.
          {:error,
           %{
             code: :E_JOURNAL_BLOCKED,
             reason: "journal blocked during reconstruction",
             session_id: sid,
             block: block
           }}
      end
    end
  end
end
