defmodule FastTS.Router.ModulesLoader do
  require Logger

  @moduledoc """
  Component responsible for loading and starting End User provided Router modules

  This is a transient process, that dies after everything is loaded successfully
  """

  def start_link do
    Task.start_link(&run/0)
  end

  defp run do
    # Load End User provided Router Modules
    # and Start the pipelines Process
    # 
    # Once everything is loaded successfully, the process ends.

    load_modules
    start_pipelines
  end

  defp load_modules do
    get_route_dir
    |> list_route_files
    |> check_route_files
    |> load_route_files
  end

  defp start_pipelines do
    FastTS.Router.Modules.pipelines
    |> Enum.map(&start_pipeline/1)
  end

  defp start_pipeline({name, pipeline}) do
    FastTS.Supervisor.start_pipeline!(name, pipeline)
  end

  defp get_route_dir do
    # Try from FTS_ROUTE_DIR env, fallback to config file
    System.get_env("FTS_ROUTE_DIR") || Application.get_env(:fast_ts, :route_dir)
  end

  # List route files in route_dir.
  # Default to config/routes.exs if no route_dir provided
  defp list_route_files(nil) do
    Logger.warning "No fast_ts route_dir configured: Using route file 'config/route.exs'"
    ["config/route.exs"]
  end
  defp list_route_files(route_dir) do
    File.ls!(route_dir)
    |> Enum.filter(fn file -> Path.extname(file) == ".exs" end)
    |> Enum.map(fn file -> Path.join(route_dir, file) end)
  end

  # Display warning if no route modules provided, and fallback to a sensible default
  defp check_route_files([]) do
    Logger.error "No .exs file in route_dir"
    # TODO register a default dumb pipeline that output everything to logs
    []
  end
  defp check_route_files(exs_files) do
    exs_files
  end

  # Compile all module files (.exs)
  defp load_route_files(exs_files) do
    exs_files
    |> Enum.map(&Code.load_file/1)
  end

end