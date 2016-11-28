defmodule Benchee.Formatters.PlotlyJS do
  require EEx

  EEx.function_from_file :def, :report,
                         "priv/templates/report.html.eex",
                         [:suite, :suite_json]

  @moduledoc """
  Functionality for converting Benchee benchmarking results to an HTML page
  with plotly_js generated graphs and friends.
  """

  @doc """
  Uses `Benchee.Formatters.PlotlyJS.format/1` to transform the statistics output to
  HTML with JS, but also already writes it to a file defined in the initial
  configuration under `%{plotly_js: %{file: "my.html"}}`
  """
  def output(map)
  def output(suite = %{config: %{plotly_js: %{file: filename}} }) do
    # copy_asset_files_to_destination

    suite
    |> format
    |> Benchee.Utility.File.each_input(filename, fn(file, content) ->
         IO.write(file, content)
       end)



    suite
  end
  def output(_suite) do
    raise "You need to specify a file to write the csv to in the configuration as %{csv: %{file: \"my.html\"}}"
  end

  @doc """
  Transforms the statistical results from benchmarking to html to be written
  somewhere, such as a file through `IO.write/2`.

  """
  def format(%{statistics: statistics, run_times: run_times}) do
    Enum.map(statistics, fn({input, input_stats}) ->
      input_run_times = run_times[input]
      input_json = Benchee.Formatters.JSON.format_measurements(statistics, run_times)
      input_suite = %{statistics: input_stats, run_times: input_run_times}
      {input, report(input_suite, input_json)}
    end) |> Map.new
  end

  defp format_duration(duration) do
    Benchee.Conversion.Format.format(duration, "", "")
  end

  defp format_count(count) do
    Benchee.Conversion.Format.format({count, :one}, Benchee.Conversion.Count)
  end
end
