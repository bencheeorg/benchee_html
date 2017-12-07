defmodule Benchee.Formatters.HTMLTest do
  use ExUnit.Case
  alias Benchee.Formatters.HTML
  import ExUnit.CaptureIO
  doctest Benchee.Formatters.HTML

  @test_directory "test_output"
  @filename "#{@test_directory}/my.html"
  @expected_filename "#{@test_directory}/my_some_input_comparison.html"
  @system_info %{
    elixir: "1.4.0",
    erlang: "19.1",
    os: "macOS",
    available_memory: "2 GB",
    cpu_speed: "2.80GHz",
    num_cores: 2
  }
  @scenario %Benchee.Benchmark.Scenario{
    job_name: "My Job",
    run_times: [190, 200, 210],
    input_name: "Some Input",
    input: "Some Input",
    run_time_statistics: %Benchee.Statistics{
      average:       200.0,
      ips:           5000.0,
      std_dev:       20,
      std_dev_ratio: 0.1,
      std_dev_ips:   500,
      median:        190.0,
      sample_size:   3,
      minimum:       190,
      maximum:       210
    }
  }
  @sample_suite %Benchee.Suite{
                   scenarios: [@scenario],
                   system: @system_info,
                   configuration: %Benchee.Configuration{
                     formatter_options: %{html: %{file: @filename, auto_open: false}}
                   }
                 }
  test ".format returns an HTML-ish string for every input" do
    {format, _} = HTML.format @sample_suite

    Enum.each format, fn({_, html}) ->
      assert html =~ ~r/<html>.+<article>.+<\/html>/si
    end
  end

  test ".format has the important suite data in the html result" do
    Enum.each comparison_and_job_htmls(), fn(html) ->
      assert_includes html,
        [
          "[190,200,210]", "\"average\":200.0", "\"median\":190.0",
          "\"ips\":5.0e3", "My Job", ">3<", ">190 μs<", ">210 μs<", ">200 μs<",
          "5 K"
        ]
    end
  end

  test ".format has system info in the html result" do
    Enum.each comparison_and_job_htmls(), fn(html) ->
      assert_includes html,
        [
          "Elixir: #{@system_info[:elixir]}",
          "Erlang: #{@system_info[:erlang]}",
          "Operating system: #{@system_info[:os]}",
          "Available memory: #{@system_info[:available_memory]}",
          "CPU Information: #{@system_info[:cpu_speed]}",
          "Number of Available Cores: #{@system_info[:num_cores]}",
        ]
    end
  end

  test ".format also scales the run times to ms" do
    statistics = %Benchee.Statistics{
      average:       1500.0,
      ips:           666.66,
      std_dev:       150,
      std_dev_ratio: 0.1,
      std_dev_ips:   66.66,
      median:        1400.0,
      sample_size:   3,
      minimum:       1300,
      maximum:       1700
    }
    scenario = %Benchee.Benchmark.Scenario{
      @scenario | run_time_statistics: statistics
    }
    suite = %Benchee.Suite{@sample_suite | scenarios: [scenario]}

    Enum.each comparison_and_job_htmls(suite), fn(html) ->
      assert_includes html,
        [">1.50 ms<", ">666.66<", ">1.40 ms<", ">1.30 ms<", ">1.70 ms<"]
    end
  end

  test ".format produces the right JSON data without the input level" do
    {%{["Some Input", "comparison"] => html}, _} = HTML.format @sample_suite

    assert html =~ "{\"statistics\":{\"My Job\""
  end

  test ".format shows the units alright" do
    Enum.each comparison_and_job_htmls(), fn(html) ->
      assert html =~ "±"
      assert html =~ "μs"
    end
  end

  defp comparison_and_job_htmls(suite \\ @sample_suite) do
    {%{["Some Input", "comparison"] => comparison_html,
      ["Some Input", "My Job"] => job_html}, _} = HTML.format suite

    [comparison_html, job_html]
  end

  test ".format mentions the input" do
    {format, _} = HTML.format @sample_suite

    Enum.each format, fn({_, html}) ->
      assert html =~ "Some Input"
    end
  end

  test ".format does not render the label if no input was given" do
    marker = Benchee.Benchmark.no_input()
    suite = %Benchee.Suite{
               scenarios: [
                 %Benchee.Benchmark.Scenario{
                   job_name: "My Job",
                   run_times: [190, 200, 210],
                   input_name: marker,
                   input: marker,
                   run_time_statistics: %Benchee.Statistics{
                   average:       200.0,
                   ips:           5000.0,
                   std_dev:       20,
                   std_dev_ratio: 0.1,
                   std_dev_ips:   500,
                   median:        190.0,
                   sample_size:   3,
                   minimum:       190,
                   maximum:       210
                   }
                 }
               ],
               system: @system_info,
               configuration: %Benchee.Configuration{
                 formatter_options: %{html: %{file: @filename, auto_open: false}}
               }
             }

    {format, _} = HTML.format suite

    Enum.each format, fn({_, html}) ->
      refute html =~ "#{marker}"
      refute html =~ "input-label"
    end
  end

  defp assert_includes(html, expected_contents) do
    Enum.each expected_contents, fn(expected_content) ->
      assert html =~ expected_content
    end
  end

  test ".output returns the suite again unchanged, produces files" do
    capture_io fn ->
      return = Benchee.Formatters.HTML.output(@sample_suite)
      assert return == @sample_suite
    end

    assert File.exists? @expected_filename
    assert_assets_copied()

    content = File.read! @expected_filename
    assert_includes content, ["My Job", "average"]
  after
    if File.exists?(@test_directory), do: File.rm_rf! @test_directory
  end

  test "assets should not be copied when assets inlining is on" do
    suite = %Benchee.Suite{
              scenarios: [@scenario],
              system: @system_info,
              configuration: %Benchee.Configuration{
                formatter_options: %{html: %{file: @filename, auto_open: false, inline_assets: true}}
              }
            }

    capture_io fn ->
      return = Benchee.Formatters.HTML.output(suite)
      assert return == suite
    end

    assert File.exists? @expected_filename

    content = File.read! @expected_filename
    assets_inlined content, ["<style>", "<script>"]

    refute File.exists? "#{@test_directory}/assets/javascripts/benchee.js"
    refute File.exists? "#{@test_directory}/assets/javascripts/plotly-1.30.1.min.js"
  after
    if File.exists?(@test_directory), do: File.rm_rf! @test_directory
  end

  defp assets_inlined(html, assets) do
    Enum.each assets, fn(asset) ->
      assert html =~ asset
    end
  end

  test ".output lets you know where it put the html" do
    output = capture_io fn ->
      Benchee.Formatters.HTML.output(@sample_suite)
    end

    assert output =~ @expected_filename
    assert File.exists? @expected_filename
  after
    if File.exists?(@test_directory), do: File.rm_rf! @test_directory
  end

  defp assert_assets_copied do
    assert File.exists? "#{@test_directory}/assets/javascripts/benchee.js"
    assert File.exists? "#{@test_directory}/assets/javascripts/plotly-1.30.1.min.js"
  end
end
