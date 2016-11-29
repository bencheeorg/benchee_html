defmodule Benchee.Formatters.HTML do
  require EEx
  alias Benchee.Conversion.{Format, Duration, Count, DeviationPercent}
  alias Benchee.Utility.FileCreation
  alias Benchee.Formatters.JSON

  EEx.function_from_file :def, :report,
                         "priv/templates/report.html.eex",
                         [:input_name, :suite, :suite_json]

  @moduledoc """
  Functionality for converting Benchee benchmarking results to an HTML page
  with plotly.js generated graphs and friends.
  """

  @doc """
  Uses `Benchee.Formatters.HTML.format/1` to transform the statistics output to
  HTML with JS, but also already writes it to a file defined in the initial
  configuration under `html: [file: "my.html"]`
  """
  def output(map)
  def output(suite = %{config: %{html: %{file: filename}}}) do
    base_directory = create_base_directory(filename)
    copy_asset_files(base_directory)

    suite
    |> format
    |> FileCreation.each(filename)

    suite
  end
  def output(_suite) do
    raise "You need to specify a file to write the HTML to in the configuration as html: [file: \"my.html\"]"
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

  """
  def format(%{statistics: statistics, run_times: run_times, system: system}) do
    statistics
    |> Enum.map(fn({input, input_stats}) ->
         sorted_stats = Benchee.Statistics.sort input_stats
         input_run_times = run_times[input]
         input_json = JSON.format_measurements(input_stats, input_run_times)
         input_suite = %{
           statistics: sorted_stats,
           run_times:  input_run_times,
           system:     system,
           job_count:  length(sorted_stats)
         }
         {input, report(input, input_suite, input_json)}
       end)
    |> Map.new
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

  defp render_input_label?(input_name) do
    input_name != Benchee.Benchmark.no_input
  end

  @job_count_class "job-count-"
  # there seems to be no way to set a maximum bar width other than through chart
  # allowed width... or I can't find it.
  defp max_width_class(job_count) when job_count < 7 do
    "#{@job_count_class}#{job_count}"
  end
  defp max_width_class(_job_count), do: ""
end
