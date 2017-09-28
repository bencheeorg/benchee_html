defmodule Benchee.Formatters.HTMLTest do
  use ExUnit.Case
  alias Benchee.Formatters.HTML
  import ExUnit.CaptureIO
  doctest Benchee.Formatters.HTML

  @test_directory "test_output"
  @filename "#{@test_directory}/my.html"
  @expected_filename "#{@test_directory}/my_some_input_comparison.html"
  @sample_suite %Benchee.Suite{
                   scenarios: [
                     %Benchee.Benchmark.Scenario{
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
                   ],
                   system: %{elixir: "1.4.0", erlang: "19.1"},
                   configuration: %Benchee.Configuration{
                     formatter_options: %{html: %{file: @filename}}
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
        ["[190,200,210]", "\"average\":200.0", "\"median\":190.0","\"ips\":5.0e3",
         "My Job", ">3<", ">190 μs<", ">210 μs<", ">200 μs<"]
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

  defp comparison_and_job_htmls do
    {%{["Some Input", "comparison"] => comparison_html,
      ["Some Input", "My Job"] => job_html}, _} = HTML.format @sample_suite

    [comparison_html, job_html]
  end

  test ".format includes the elixir and erlang version everywhere" do
    {format, _} = HTML.format @sample_suite

    Enum.each format, fn({_, html}) ->
      assert html =~ "Elixir 1.4.0"
      assert html =~ "Erlang 19.1"
    end
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
               system: %{elixir: "1.4.0", erlang: "19.1"},
               configuration: %Benchee.Configuration{
                 formatter_options: %{html: %{file: @filename}}
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

  test ".output returns the suite again unchanged and produces files" do
    try do
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
  end

  test ".output let's you know where it put the html" do
    try do
      output = capture_io fn ->
        Benchee.Formatters.HTML.output(@sample_suite)
      end

      assert output =~ @expected_filename
      assert File.exists? @expected_filename
    after
      if File.exists?(@test_directory), do: File.rm_rf! @test_directory
    end
  end

  defp assert_assets_copied do
    assert File.exists? "#{@test_directory}/assets/javascripts/benchee.js"
    assert File.exists? "#{@test_directory}/assets/javascripts/plotly-1.30.1.min.js"
  end
end
