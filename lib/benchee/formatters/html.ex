defmodule Benchee.Formatters.HTML do
  @behaviour Benchee.Formatter
  require EEx
  alias Benchee.{Suite, Statistics, Configuration}
  alias Benchee.Conversion
  alias Benchee.Conversion.{Duration, Count, DeviationPercent}
  alias Benchee.Utility.FileCreation
  alias Benchee.Formatters.JSON

  # Major pages
  EEx.function_from_file :defp, :comparison,
                         "priv/templates/comparison.html.eex",
                         [:input_name, :suite, :units, :suite_json]
  EEx.function_from_file :defp, :job_detail,
                         "priv/templates/job_detail.html.eex",
                         [:input_name, :job_name, :job_statistics, :system,
                          :units, :job_json]
  EEx.function_from_file :defp, :index,
                         "priv/templates/index.html.eex",
                         [:names_to_paths, :system]

  # Partials
  EEx.function_from_file :defp, :head,
                         "priv/templates/partials/head.html.eex",
                         []
  EEx.function_from_file :defp, :header,
                         "priv/templates/partials/header.html.eex",
                         [:input_name, :system]
  EEx.function_from_file :defp, :js_includes,
                         "priv/templates/partials/js_includes.html.eex",
                         []
  EEx.function_from_file :defp, :version_note,
                         "priv/templates/partials/version_note.html.eex",
                         [:system]
  EEx.function_from_file :defp, :input_label,
                         "priv/templates/partials/input_label.html.eex",
                         [:input_name]
  EEx.function_from_file :defp, :data_table,
                         "priv/templates/partials/data_table.html.eex",
                         [:statistics, :units, :options]

  # Small wrapper to have default arguments
  defp render_data_table(statistics, units, options \\ []) do
    data_table statistics, units, options
  end

  @moduledoc """
  Functionality for converting Benchee benchmarking results to an HTML page
  with plotly.js generated graphs and friends.

  ## Examples

      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      Benchee.run(%{
        "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
      },
        formatters: [
          &Benchee.Formatters.HTML.output/1,
          &Benchee.Formatters.Console.output/1
        ],
        formatter_options: [html: [file: "samples_output/flat_map.html"]],
      )

  """

  @doc """
  Uses `Benchee.Formatters.HTML.format/1` to transform the statistics output to
  HTML with JS, but also already writes it to files defined in the initial
  configuration under `formatter_options: [html: [file:
  "benchmark_out/my.html"]]`.

  Generates the following files:

  * index file (exactly like `file` is named)
  * a comparison of all the benchmarked jobs (one per benchmarked input)
  * for each job a detail page with more detailed run time graphs for that
    particular job (one per benchmark input)
  """
  @spec output(Suite.t) :: Suite.t
  def output(suite = %{configuration: %{formatter_options: %{html: %{file: _, auto_open: auto_open?}}}}) do
    suite
    |> format
    |> write

    if auto_open?, do: open_report(suite)
    suite
  end

  @default_filename "benchmark_output/my.html"
  def output(suite) do
    suite
    |> update_filename()
    |> output()
  end

  defp update_filename(suite) do
    updated_configuration = %Configuration{suite.configuration | formatter_options: %{html: %{file: @default_filename}}}
    %Suite{suite | configuration: updated_configuration}
  end

  @doc """
  Transforms the statistical results from benchmarking to html to be written
  somewhere, such as a file through `IO.write/2`.

  Returns a map from file name/path to file content.
  """
  @spec format(Suite.t) :: {%{Suite.key => String.t}, String.t}
  def format(%Suite{scenarios: scenarios, system: system,
               configuration: %{
                 formatter_options: %{html: %{file: filename}},
                 unit_scaling: unit_scaling
               }}) do
    data = scenarios
           |> Enum.group_by(fn(scenario) -> scenario.input_name end)
           |> Enum.map(fn(tagged_scenarios) -> reports_for_input(tagged_scenarios, system, filename, unit_scaling) end)
           |> add_index(filename, system)
           |> List.flatten
           |> Map.new

    {data, filename}
  end

  @spec write({%{Suite.key => String.t}, String.t}) :: :ok
  def write({data, filename}) do
    filename |> create_base_directory |> copy_asset_files

    FileCreation.each(data, filename)
    :ok
  end

  defp create_base_directory(filename) do
    base_directory = Path.dirname filename
    File.mkdir_p! base_directory
    base_directory
  end

  @asset_directory "assets"
  defp copy_asset_files(base_directory) do
    asset_target_directory = Path.join(base_directory, @asset_directory)
    asset_source_directory = Application.app_dir(:benchee_html,
                                                 "priv/assets/")
    File.cp_r! asset_source_directory, asset_target_directory
  end

  defp reports_for_input({input_name, scenarios}, system, filename, unit_scaling) do
    units = Conversion.units(scenarios, unit_scaling)
    job_reports = job_reports(input_name, scenarios, system, units)
    comparison  = comparison_report(input_name, scenarios, system, filename, units)
    [comparison | job_reports]
  end

  defp job_reports(input_name, scenarios, system, units) do
    # extract some of me to benchee_json pretty please?
    Enum.map(scenarios, fn(scenario) ->
      job_json = JSON.encode!(%{
        statistics: scenario.run_time_statistics,
        run_times: scenario.run_times
      })
      {
        [input_name, scenario.job_name],
        job_detail(input_name, scenario.job_name, scenario.run_time_statistics, system, units, job_json)
      }
    end)
  end

  defp comparison_report(input_name, scenarios, system, filename, units) do
    input_json = JSON.format_scenarios_for_input(scenarios)

    sorted_statistics = scenarios
                        |> Statistics.sort()
                        |> Enum.map(fn(scenario) -> {scenario.job_name, %{run_time_statistics: scenario.run_time_statistics}} end)
                        |> Map.new

    input_run_times = scenarios
                      |> Enum.map(fn(scenario) -> {scenario.job_name, scenario.run_times} end)
                      |> Map.new
    input_suite = %{
      statistics: sorted_statistics,
      run_times:  input_run_times,
      system:     system,
      job_count:  length(scenarios),
      filename:   filename
    }

    {[input_name, "comparison"], comparison(input_name, input_suite, units, input_json)}
  end

  defp add_index(grouped_main_contents, filename, system) do
    index_structure = inputs_to_paths(grouped_main_contents, filename)
    index_entry = {[], index(index_structure, system)}
    [index_entry | grouped_main_contents]
  end

  defp inputs_to_paths(grouped_main_contents, filename) do
    grouped_main_contents
    |> Enum.map(fn(reports) -> input_to_paths(reports, filename) end)
    |> Map.new
  end

  defp input_to_paths(input_reports, filename) do
    [{[input_name | _], _} | _] = input_reports

    paths = Enum.map input_reports, fn({tags, _content}) ->
      relative_file_path(filename, tags)
    end
    {input_name, paths}
  end

  defp relative_file_path(filename, tags) do
    filename
    |> Path.basename
    |> FileCreation.interleave(tags)
  end

  defp format_duration(duration, unit) do
    Duration.format({Duration.scale(duration, unit), unit})
  end

  defp format_count(count, unit) do
    Count.format({Count.scale(count, unit), unit})
  end

  defp format_percent(deviation_percent) do
    DeviationPercent.format deviation_percent
  end

  @no_input Benchee.Benchmark.no_input()
  defp inputs_supplied?(@no_input), do: false
  defp inputs_supplied?(_), do: true

  defp input_headline(input_name) do
    if inputs_supplied?(input_name) do
      " (#{input_name})"
    else
      ""
    end
  end

  @job_count_class "job-count-"
  # there seems to be no way to set a maximum bar width other than through chart
  # allowed width... or I can't find it.
  defp max_width_class(job_count) when job_count < 7 do
    "#{@job_count_class}#{job_count}"
  end
  defp max_width_class(_job_count), do: ""

  defp open_report(suite) do
    browser = get_browser()
    {_, exit_code} = System.cmd(browser, [suite.configuration.formatter_options.html.file])
    unless exit_code > 0, do: IO.puts "Opened report using #{browser}"
  end

  defp get_browser do
    case :os.type() do
      {:unix, :darwin} -> "open"
      {:unix, _} -> "xdg-open"
      {:win32, _} -> "explorer"
    end
  end
end
