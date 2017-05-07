defmodule Benchee.Formatters.HTML do
  require EEx
  alias Benchee.Conversion.{Format, Duration, Count, DeviationPercent}
  alias Benchee.Utility.FileCreation
  alias Benchee.Formatters.JSON

  # Major pages
  EEx.function_from_file :defp, :comparison,
                         "priv/templates/comparison.html.eex",
                         [:input_name, :suite, :suite_json]
  EEx.function_from_file :defp, :job_detail,
                         "priv/templates/job_detail.html.eex",
                         [:input_name, :job_name,  :measurements, :system,
                          :job_json]
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
                         [:statistics, :options]

  # Small wrapper to have default arguments
  defp render_data_table(statistics, options \\ []) do
    data_table statistics, options
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
  @spec output(Benchee.Suite.t) :: Benchee.Suite.t
  def output(map)
  def output(suite = %{configuration:
                       %{formatter_options:
                         %{html: %{file: filename}}}}) do
    base_directory = create_base_directory(filename)
    copy_asset_files(base_directory)

    suite
    |> format
    |> FileCreation.each(filename)

    suite
  end
  def output(_suite) do
    raise "You need to specify a file to write the HTML to in the configuration as formatter_options: [html: [file: \"my.html\"]]"
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

  @doc """
  Transforms the statistical results from benchmarking to html to be written
  somewhere, such as a file through `IO.write/2`.

  Returns a map from file name/path to file content.
  """
  @spec format(Benchee.Suite.t) :: %{Benchee.Suite.key => String.t}
  def format(%{statistics: statistics, run_times: run_times, system: system,
               configuration: %{
                 formatter_options: %{html: %{file: filename}}}}) do
    statistics
    |> input_job_reports(run_times, system, filename)
    |> add_index(filename, system)
    |> List.flatten
    |> Map.new
  end

  defp input_job_reports(statistics, run_times, system, filename) do
    Enum.map statistics, fn({input, input_stats}) ->
      input_run_times = Map.fetch! run_times, input
      reports_for_input(input, input_stats, input_run_times, system, filename)
    end
  end

  defp reports_for_input(input, input_stats, input_run_times, system, filename) do
    job_reports = job_reports(input, input_stats, input_run_times, system)
    comparison  = comparison_report(input, input_stats, input_run_times, system, filename)
    [comparison | job_reports]
  end

  defp comparison_report(input, input_stats, input_run_times, system, filename) do
    input_json = JSON.format_measurements(input_stats, input_run_times)
    sorted_stats = Benchee.Statistics.sort input_stats
    input_suite = %{
      statistics: sorted_stats,
      run_times:  input_run_times,
      system:     system,
      job_count:  length(sorted_stats),
      filename:   filename
    }
    {[input, "comparison"], comparison(input, input_suite, input_json)}
  end

  defp job_reports(input, input_stats, input_run_times, system) do
    merged_stats = merge_job_measurements(input_stats, input_run_times)
    # extract some of me to benchee_json pretty please?
    Enum.map(merged_stats, fn({job_name, measurements}) ->
      job_json = JSON.encode!(measurements)
      {[input, job_name],
       job_detail(input, job_name, measurements, system, job_json)}
    end)
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

  @doc """
  Given statistics and run times for an input get all the data of a job
  together.

  ## Exmaples

      iex> statistics = %{
      ...>   "Job"   => %{average: 500.0},
      ...>   "Other" => %{average: 200.0}
      ...> }
      iex> run_times = %{"Job" => [400, 600], "Other" => [150, 250]}
      iex> Benchee.Formatters.HTML.merge_job_measurements(statistics, run_times)
      %{
        "Job" => %{
          statistics: %{average: 500.0},
          run_times:  [400, 600]
        },
        "Other" => %{
          statistics: %{average: 200.0},
          run_times: [150, 250]
        }
      }
  """
  def merge_job_measurements(statistics, run_times) do
    Map.merge(statistics, run_times, fn(_key, stats, times) ->
      %{
        statistics: stats,
        run_times: times
      }
    end)
  end

  defp format_duration(duration) do
    Format.format({:erlang.float(duration), :microsecond}, Duration)
  end

  defp format_count(count) do
    Format.format({count, :one}, Count)
  end

  defp format_percent(deviation_percent) do
    DeviationPercent.format deviation_percent
  end

  defp inputs_supplied?(input_name) do
    input_name != Benchee.Benchmark.no_input
  end

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
end
