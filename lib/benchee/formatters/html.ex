defmodule Benchee.Formatters.HTML do
  @moduledoc """
  Functionality for converting Benchee benchmarking results to an HTML page
  with plotly.js generated graphs and friends.

  ## Examples

    list = Enum.to_list(1..10_000)
    map_fun = fn(i) -> [i, i * i] end

    Benchee.run(
      %{
        "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
      },
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML, file: "samples_output/flat_map.html"}
      ]
    )
  """

  @behaviour Benchee.Formatter

  alias Benchee.{
    Configuration,
    Conversion,
    Formatters.HTML.Render,
    Formatters.JSON,
    Suite,
    Utility.FileCreation
  }
  alias Benchee.Benchmark.Scenario

  @doc """
  Transforms the statistical results from benchmarking to html reports.

  Returns a map from file name/path to file content.
  """
  @spec format(Suite.t(), map) :: %{Suite.key() => String.t()}
  def format(
        %Suite{
          scenarios: scenarios,
          system: system,
          configuration: %Configuration{unit_scaling: unit_scaling}
        },
        opts
      ) do
    ensure_applications_loaded()
    %{file: filename, inline_assets: inline_assets} = default_configuration(opts)

    scenarios
    |> Enum.group_by(fn scenario -> scenario.input_name end)
    |> Enum.map(fn tagged_scenarios ->
      reports_for_input(tagged_scenarios, system, filename, unit_scaling, inline_assets)
    end)
    |> add_index(filename, system, inline_assets)
    |> List.flatten()
    |> Map.new()
  end

  @doc """
  Writes the output of `Benchee.Formatters.HTML.format/2` to disk.

  Generates the following files:

  * index file (exactly like `file` is named)
  * a comparison of all the benchmarked jobs (one per benchmarked input)
  * for each job a detail page with more detailed run time graphs for that
    particular job (one per benchmark input)
  """
  @spec write(%{Suite.key() => String.t()}, map) :: :ok
  def write(data, opts) do
    %{
      file: filename,
      auto_open: auto_open?,
      inline_assets: inline_assets?
    } = default_configuration(opts)

    prepare_folder_structure(filename, inline_assets?)
    FileCreation.each(data, filename)
    if auto_open?, do: open_report(filename)
    :ok
  end

  defp ensure_applications_loaded do
    _ = Application.load(:benchee)
    _ = Application.load(:benchee_html)
  end

  @default_filename "benchmarks/output/results.html"
  @default_auto_open true
  @default_inline_assets false
  defp default_configuration(opts) do
    opts
    |> Map.put_new(:file, @default_filename)
    |> Map.put_new(:auto_open, @default_auto_open)
    |> Map.put_new(:inline_assets, @default_inline_assets)
  end

  defp prepare_folder_structure(filename, inline_assets?) do
    base_directory = create_base_directory(filename)
    unless inline_assets?, do: copy_asset_files(base_directory)
    base_directory
  end

  defp create_base_directory(filename) do
    base_directory = Path.dirname(filename)
    File.mkdir_p!(base_directory)
    base_directory
  end

  @asset_directory "assets"
  defp copy_asset_files(base_directory) do
    asset_target_directory = Path.join(base_directory, @asset_directory)
    asset_source_directory = Application.app_dir(:benchee_html, "priv/assets/")
    File.cp_r!(asset_source_directory, asset_target_directory)
  end

  defp reports_for_input({input_name, scenarios}, system, filename, unit_scaling, inline_assets) do
    units = Conversion.units(scenarios, unit_scaling)
    scenario_reports = scenario_reports(input_name, scenarios, system, units, inline_assets)
    comparison = comparison_report(input_name, scenarios, system, filename, units, inline_assets)
    [comparison | scenario_reports]
  end

  defp scenario_reports(input_name, scenarios, system, units, inline_assets) do
    Enum.map(scenarios, fn scenario ->
      scenario_json = JSON.encode!(scenario)

      {
        [input_name, scenario.name],
        Render.scenario_detail(
          scenario,
          scenario_json,
          system,
          units,
          inline_assets
        )
      }
    end)
  end

  defp comparison_report(input_name, scenarios, system, filename, units, inline_assets) do
    scenarios_json = JSON.encode!(scenarios)

    run_time_statistics = prepare_table_data(scenarios, :run_time_statistics)

    memory_statistics =
      if all_memory_statistics_present?(scenarios) do
        prepare_table_data(scenarios, :memory_usage_statistics)
      else
        nil
      end

    input_suite = %{
      run_time_statistics: run_time_statistics,
      memory_usage_statistics: memory_statistics,
      system: system,
      job_count: length(scenarios),
      filename: filename
    }

    {[input_name, "comparison"],
     Render.comparison(input_name, input_suite, units, scenarios_json, inline_assets)}
  end

  defp prepare_table_data(scenarios, statistics_key) do
    scenarios
    |> Enum.map(fn scenario ->
      {scenario.name, %{statistics: Map.fetch!(scenario, statistics_key)}}
    end)
    |> Map.new()
  end

  defp all_memory_statistics_present?(scenarios) do
    Enum.all?(scenarios, fn scenario -> Scenario.data_processed?(scenario, :memory) end)
  end

  defp add_index(grouped_main_contents, filename, system, inline_assets) do
    index_structure = inputs_to_paths(grouped_main_contents, filename)
    index_entry = {[], Render.index(index_structure, system, inline_assets)}
    [index_entry | grouped_main_contents]
  end

  defp inputs_to_paths(grouped_main_contents, filename) do
    grouped_main_contents
    |> Enum.map(fn reports -> input_to_paths(reports, filename) end)
    |> Map.new()
  end

  defp input_to_paths(input_reports, filename) do
    [{[input_name | _], _} | _] = input_reports

    paths =
      Enum.map(input_reports, fn {tags, _content} ->
        Render.relative_file_path(filename, tags)
      end)

    {input_name, paths}
  end

  defp open_report(filename) do
    browser = get_browser()
    {_, exit_code} = System.cmd(browser, [filename])
    unless exit_code > 0, do: IO.puts("Opened report using #{browser}")
  end

  defp get_browser do
    case :os.type() do
      {:unix, :darwin} -> "open"
      {:unix, _} -> "xdg-open"
      {:win32, _} -> "explorer"
    end
  end
end
