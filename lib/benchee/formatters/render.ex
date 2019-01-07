defmodule Benchee.Formatters.HTML.Render do
  @moduledoc """
  Functions to render HTML templates.
  """

  require EEx

  alias Benchee.Conversion.{Count, DeviationPercent, Duration}
  alias Benchee.Utility.FileCreation

  # Major pages
  EEx.function_from_file(:def, :comparison, "priv/templates/comparison.html.eex", [
    :input_name,
    :suite,
    :units,
    :scenarios_json,
    :inline_assets
  ])

  EEx.function_from_file(
    :def,
    :run_time_scenario_detail,
    "priv/templates/run_time_scenario_detail.html.eex",
    [
      :input_name,
      :scenario_name,
      :scenario_statistics,
      :system,
      :units,
      :scenario_json,
      :inline_assets
    ]
  )

  EEx.function_from_file(
    :def,
    :memory_scenario_detail,
    "priv/templates/memory_scenario_detail.html.eex",
    [
      :input_name,
      :scenario_name,
      :scenario_statistics,
      :system,
      :units,
      :scenario_json,
      :inline_assets
    ]
  )

  EEx.function_from_file(:def, :index, "priv/templates/index.html.eex", [
    :names_to_paths,
    :system,
    :inline_assets
  ])

  # Partials
  EEx.function_from_file(:defp, :head, "priv/templates/partials/head.html.eex", [:inline_assets])
  EEx.function_from_file(:defp, :header, "priv/templates/partials/header.html.eex", [:input_name])

  EEx.function_from_file(:defp, :js_includes, "priv/templates/partials/js_includes.html.eex", [
    :inline_assets
  ])

  EEx.function_from_file(
    :defp,
    :version_note,
    "priv/templates/partials/version_note.html.eex",
    []
  )

  EEx.function_from_file(:defp, :input_label, "priv/templates/partials/input_label.html.eex", [
    :input_name
  ])

  EEx.function_from_file(:defp, :data_table, "priv/templates/partials/data_table.html.eex", [
    :statistics,
    :units,
    :options
  ])

  EEx.function_from_file(:defp, :system_info, "priv/templates/partials/system_info.html.eex", [
    :system,
    :options
  ])

  EEx.function_from_file(:defp, :footer, "priv/templates/partials/footer.html.eex", [
    :dependencies
  ])

  def relative_file_path(filename, tags) do
    filename
    |> Path.basename()
    |> FileCreation.interleave(tags)
  end

  # Small wrappers to have default arguments
  defp render_data_table(statistics, units, options) do
    data_table(statistics, units, options)
  end

  defp render_system_info(system, options \\ [visible: false]) do
    system_info(system, options)
  end

  defp render_footer do
    footer(%{
      benchee: Application.spec(:benchee, :vsn),
      benchee_html: Application.spec(:benchee_html, :vsn)
    })
  end

  defp format_duration(duration, unit) do
    Duration.format({Duration.scale(duration, unit), unit})
  end

  defp format_count(count, unit) do
    Count.format({Count.scale(count, unit), unit})
  end

  defp format_percent(deviation_percent) do
    DeviationPercent.format(deviation_percent)
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
end
