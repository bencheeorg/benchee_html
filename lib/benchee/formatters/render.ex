defmodule Benchee.Formatters.HTML.Render do
  @moduledoc """
  Functions to render HTML templates.
  """

  require EEx

  alias Benchee.Conversion.{DeviationPercent, Format, Scale}
  alias Benchee.Benchmark.Scenario
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
    :scenario_detail,
    "priv/templates/scenario_detail.html.eex",
    [
      :scenario,
      :scenario_json,
      :system,
      :units,
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
    :scenarios,
    :statistics_key,
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

  defp render_data_table(scenarios, statistics_key, units, options \\ [])
  defp render_data_table(scenarios = [_ | _], statistics_key, units, options) do
    data_table(scenarios, statistics_key, units, options)
  end
  defp render_data_table(scenario, statistics_key, units, options) do
    render_data_table([scenario], statistics_key, units, options)
  end

  defp all_scenarios_processed?(scenarios, type) do
    Enum.all?(scenarios, fn scenario -> Scenario.data_processed?(scenario, type) end)
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

  defp format_property(value, unit) do
    Format.format({Scale.scale(value, unit), unit})
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
