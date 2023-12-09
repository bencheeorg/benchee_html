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

  @doc """
  Transforms the statistical results from benchmarking to html reports.

  Returns a map from file name/path to file content. This list is ready to be put into
  `Benchee.Utility.FileCreation.each/3`. It's a list of names to be "interleaved" with
  a main file name that points to the contents of the file. For example:application

      %{["big list", "flat_map"] => "...file content..."}
  """
  @spec format(Suite.t(), map) :: %{list(String.t()) => String.t()}
  def format(
        %Suite{
          scenarios: scenarios,
          system: system,
          configuration: %Configuration{unit_scaling: unit_scaling}
        },
        opts
      ) do
    ensure_applications_loaded()
    %{file: filename, inline_assets: inline_assets} = merge_default_configuration(opts)

    scenario_data =
      scenarios
      # at best we'd keep the input order here, so no grouping
      |> Enum.group_by(fn scenario -> scenario.input_name end)
      |> Enum.map(fn input_to_scenarios = {input_name, _scenarios} ->
        # build index data
        {input_name,
         reports_for_input(input_to_scenarios, system, filename, unit_scaling, inline_assets)}
      end)

    index_data =
      Enum.map(scenario_data, fn {input_name, {input_index_data, _input_scenarios}} ->
        {input_name, input_index_data}
      end)

    scenario_pages =
      Enum.flat_map(scenario_data, fn {_input_name, {_input_index_data, input_scenarios}} ->
        input_scenarios
      end)

    index_page = build_index(index_data, filename, system, inline_assets)

    # prolly don't need map here
    Map.new([index_page | scenario_pages])
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
    } = merge_default_configuration(opts)

    prepare_folder_structure(filename, inline_assets?)
    FileCreation.each(data, filename)
    if auto_open?, do: open_report(filename)
    :ok
  end

  @doc """
  Formats and prints out files sequentially fo consume less memory.

  Benchee loves to do things in parallel, which is usually great, less so if you have a gigantic benchmark though.
  By default, benchee's formatters first format everything in parallel (see `format/2`) - which means all that data
  needs to be kept in memory. Only a second step benchee writes the results out (see `write/2`).

  This (optional) function is supposed to format something and write it out immediately. For a formatter like HTML
  that might write out 30 files or so, this should signficantly reduce memory consumption.
  """
  def sequential_output(
        %Suite{
          scenarios: scenarios,
          system: system,
          configuration: %Configuration{unit_scaling: unit_scaling}
        },
        opts
      ) do
    ensure_applications_loaded()

    %{file: filename, auto_open: auto_open?, inline_assets: inline_assets?} =
      merge_default_configuration(opts)

    prepare_folder_structure(filename, inline_assets?)

    # names is a variant for the modifiers applied to the file on creation
    input_to_names =
      scenarios
      |> Enum.group_by(fn scenario -> scenario.input_name end)
      |> Enum.map(fn input_to_scenarios = {input_name, _scenarios} ->
        file_names =
          write_reports_for_input(
            input_to_scenarios,
            system,
            filename,
            unit_scaling,
            inline_assets?
          )

        {input_name, file_names}
      end)

    write_index(input_to_names, filename, system, inline_assets?)

    if auto_open?, do: open_report(filename)
    :ok
  end

  defp ensure_applications_loaded do
    _ = Application.load(:benchee)
    _ = Application.load(:benchee_html)
  end

  @default_configuration %{
    file: "benchmarks/output/results.html",
    auto_open: true,
    inline_assets: false
  }
  defp merge_default_configuration(opts) do
    Map.merge(@default_configuration, opts)
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

    scenario_reports =
      Enum.map(scenarios, fn scenario ->
        scenario_report(scenario, system, units, inline_assets)
      end)

    comparison = comparison_report(input_name, scenarios, system, filename, units, inline_assets)
    data = [comparison | scenario_reports]

    # getting a slight variation of the data out may seem weird but since `sequential_output/1` doesn't keep
    # the same data around it's done for _some_ consistency and not to delegate knowledge of getting index
    # data outside.
    index_data = Enum.map(data, fn {names, _content} -> names end)

    {index_data, data}
  end

  defp scenario_report(scenario, system, units, inline_assets) do
    scenario_json = JSON.encode!(scenario)

    {
      [scenario.input_name, scenario.name],
      Render.scenario_detail(
        scenario,
        scenario_json,
        system,
        units,
        inline_assets
      )
    }
  end

  defp comparison_report(input_name, scenarios, system, filename, units, inline_assets) do
    scenarios_json = JSON.encode!(scenarios)

    input_suite = %{
      system: system,
      job_count: length(scenarios),
      filename: filename,
      scenarios: scenarios
    }

    {[input_name, "comparison"],
     Render.comparison(input_name, input_suite, units, scenarios_json, inline_assets)}
  end

  defp write_reports_for_input(
         {input_name, scenarios},
         system,
         filename,
         unit_scaling,
         inline_assets
       ) do
    units = Conversion.units(scenarios, unit_scaling)

    scenario_names =
      Enum.map(scenarios, fn scenario ->
        report = {names, _content} = scenario_report(scenario, system, units, inline_assets)
        create_single_file(report, filename)

        names
      end)

    comparison_report =
      {names, _content} =
      comparison_report(input_name, scenarios, system, filename, units, inline_assets)

    create_single_file(comparison_report, filename)

    [names | scenario_names]
  end

  defp create_single_file(report, filename) do
    # yes wrapping this may feel overdone but provides an easy switch if we introduce a nicer utility to Benchee
    FileCreation.each([report], filename)
  end

  defp build_index(input_to_names, filename, system, inline_assets?) do
    full_index_data = build_index_data(input_to_names, filename)

    {[], Render.index(full_index_data, system, inline_assets?)}
  end

  defp build_index_data(input_to_names, filename) do
    Enum.map(input_to_names, fn {input_name, names_list} ->
      {input_name,
       Enum.map(names_list, fn names -> Render.relative_file_path(filename, names) end)}
    end)
  end

  defp write_index(input_to_names, filename, system, inline_assets?) do
    full_index_data = build_index_data(input_to_names, filename)
    index_entry = {[], Render.index(full_index_data, system, inline_assets?)}

    create_single_file(index_entry, filename)

    :ok
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
