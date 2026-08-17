defmodule Mix.Tasks.Kiln do
  @moduledoc """
  The source-development `mix kiln` entry point.

  This task is the smallest foreground CLI over the implemented P1-S01 domain.
  It accepts the documented global flags (`--format`, `--kiln-home`, `--help`,
  `--version`) and the P1-S01 commands (`start`, `status`, `inspect`, `cancel`,
  `resume`). It is non-authoritative presentation: every command routes through
  `Kiln.CLI.run/1` and never touches the Repository, provider, Context, Patch,
  Command, completion, Receipt, Child, or TUI behavior (P1-S01-T04-R12, R13,
  R14).

  The packaged `kiln` Mix release is not yet shipped. This is a development
  entry point and identifies itself as such.
  """

  @shortdoc "Foreground P1-S01 CLI entry point (development)"

  use Mix.Task

  def run(argv) do
    # The CLI opens an Exqlite pool through `Kiln.CLI.Runtime.open/2`. That
    # pool registers with `DBConnection.Watcher`, which exists only when the
    # `:db_connection` application (a dependency of `:exqlite`, itself a
    # dependency of `:kiln`) is running. A Mix task does not start the
    # current application automatically, so without this call every real
    # `mix kiln` invocation that opens a store crashes with an unstructured
    # BEAM exit instead of returning a `kiln.cli.result/v1` envelope. Under
    # `mix test` the applications are already started, which is why the
    # in-process T04 dispatcher tests never observed this.
    #
    # `Kiln.Application` supervises no store at boot (`:state_path` is unset),
    # so starting the application opens no database; the CLI still owns the
    # per-command store lifecycle through `Kiln.CLI.Runtime`.
    Mix.Task.run("app.start")

    case Kiln.CLI.Request.parse(argv) do
      {:ok, request} ->
        {result, exit_code} = Kiln.CLI.run(request)
        emit(request, result)
        exit({:shutdown, exit_code})

      {:error, error} ->
        request = %Kiln.CLI.Request{command: nil, format: requested_format(argv)}

        result =
          Kiln.CLI.Result.error("kiln", :denied,
            exit_code: 2,
            errors: [error]
          )

        emit(request, result)
        exit({:shutdown, result.exit_code})
    end
  end

  defp emit(request, result) do
    output = render(request, result)
    Mix.shell().info(String.trim_trailing(output, "\n"))
  end

  defp render(
         %Kiln.CLI.Request{command: :supervise, format: :json},
         %Kiln.CLI.Result{status: :ok} = result
       ),
       do: Kiln.CLI.JsonRenderer.render_supervision(result)

  defp render(%Kiln.CLI.Request{format: :json}, %Kiln.CLI.Result{} = result),
    do: Kiln.CLI.JsonRenderer.render(result)

  defp render(%Kiln.CLI.Request{}, %Kiln.CLI.Result{} = result),
    do: Kiln.CLI.TextRenderer.render(result)

  # M11 E2 B1: defensive crash containment. If a non-Result term
  # somehow reaches the renderer (e.g. a dispatcher's error term
  # was not wrapped by normalize_dispatch_result/2), emit a
  # structured bounded internal error rather than crashing the Mix
  # task. The canonical fix lives in the dispatchers; this is the
  # last-line-of-defense fallback.
  defp render(%Kiln.CLI.Request{} = request, other) do
    result =
      Kiln.CLI.Result.error(
        kiln_command_name(request.command),
        :failed,
        errors: [
          Kiln.CLI.Result.to_error(%{
            code: :internal_invalid_dispatch_result,
            message:
              "dispatcher did not return a structured %Kiln.CLI.Result{}; renderer received " <>
                inspect(other)
          })
        ]
      )

    if request.format == :json do
      Kiln.CLI.JsonRenderer.render(result)
    else
      Kiln.CLI.TextRenderer.render(result)
    end
  end

  defp kiln_command_name(nil), do: "kiln"
  defp kiln_command_name(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp kiln_command_name(_), do: "kiln"

  defp requested_format(argv) do
    if "--format=json" in argv or
         Enum.any?(Enum.chunk_every(argv, 2, 1, :discard), &(&1 == ["--format", "json"])) do
      :json
    else
      :text
    end
  end
end
