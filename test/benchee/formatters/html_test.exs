defmodule Benchee.Formatters.HTMLTest do
  use ExUnit.Case
  alias Benchee.Formatters.HTML
  import ExUnit.CaptureIO
  doctest Benchee.Formatters.HTML

  @test_directory "test_output"
  @filename "#{@test_directory}/my.html"
  @expected_filename "#{@test_directory}/my_some_input_comparison.html"
  @default_options %{file: @filename, auto_open: false}
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
    name: "My Job",
    run_times: [190, 200, 210],
    memory_usages: [190, 200, 210],
    input_name: "Some Input",
    input: "Some Input",
    run_time_statistics: %Benchee.Statistics{
      average: 200.0,
      ips: 5000.0,
      std_dev: 20,
      std_dev_ratio: 0.1,
      std_dev_ips: 500,
      median: 190.0,
      sample_size: 3,
      minimum: 190,
      maximum: 210
    },
    memory_usage_statistics: %Benchee.Statistics{
      average: 200.0,
      ips: nil,
      std_dev: 20,
      std_dev_ratio: 0.1,
      std_dev_ips: nil,
      median: 190.0,
      sample_size: 3,
      minimum: 190,
      maximum: 210
    }
  }
  @sample_suite %Benchee.Suite{
    scenarios: [@scenario],
    system: @system_info
  }

  describe "format/2" do
    test "returns an HTML-ish string for every input" do
      @sample_suite
      |> HTML.format(@default_options)
      |> Enum.each(fn {_, html} ->
        assert html =~ ~r/<html>.+<article>.+<\/html>/si
      end)
    end

    test "has the important suite data in the html result" do
      [comparison_html, run_time_html, memory_html] = comparison_and_job_htmls()

      Enum.each([comparison_html, run_time_html], fn html ->
        assert_includes(
          html,
          [
            "[190,200,210]",
            "\"average\":200.0",
            "\"median\":190.0",
            "\"ips\":5.0e3",
            "My Job",
            ">3<",
            ">190 ns<",
            ">210 ns<",
            ">200 ns<",
            "5 K"
          ]
        )
      end)

      assert_includes(memory_html, [
        "[190,200,210]",
        "\"average\":200.0",
        "\"median\":190.0",
        "My Job",
        ">3<",
        ">190 B<",
        ">210 B<",
        ">200 B<"
      ])
    end

    test "has system info in the html result" do
      Enum.each(comparison_and_job_htmls(), fn html ->
        assert_includes(
          html,
          [
            "Elixir: #{@system_info[:elixir]}",
            "Erlang: #{@system_info[:erlang]}",
            "Operating system: #{@system_info[:os]}",
            "Available memory: #{@system_info[:available_memory]}",
            "CPU Information: #{@system_info[:cpu_speed]}",
            "Number of Available Cores: #{@system_info[:num_cores]}"
          ]
        )
      end)
    end

    test "scales the run times to μs" do
      statistics = %Benchee.Statistics{
        average: 1500.0,
        ips: 666.66,
        std_dev: 150,
        std_dev_ratio: 0.1,
        std_dev_ips: 66.66,
        median: 1400.0,
        sample_size: 3,
        minimum: 1300,
        maximum: 1700
      }

      scenario = %Benchee.Benchmark.Scenario{
        @scenario
        | run_time_statistics: statistics
      }

      suite = %Benchee.Suite{@sample_suite | scenarios: [scenario]}

      [comparison_html, run_time_html, _memory_html] = comparison_and_job_htmls(suite)

      Enum.each([comparison_html, run_time_html], fn html ->
        assert_includes(
          html,
          [">1.50 μs<", ">666.66<", ">1.40 μs<", ">1.30 μs<", ">1.70 μs<"]
        )
      end)
    end

    test "produces the right JSON data without the input level" do
      %{["Some Input", "comparison"] => html} = HTML.format(@sample_suite, @default_options)
      assert html =~ "\"run_time_statistics\":{\"My Job\""
    end

    test "shows the units alright" do
      [comparison_html, run_time_html, _memory_html] = comparison_and_job_htmls()

      Enum.each([comparison_html, run_time_html], fn html ->
        assert html =~ "±"
        assert html =~ "ns"
      end)
    end

    test "mentions the input" do
      @sample_suite
      |> HTML.format(@default_options)
      |> Enum.each(fn {_, html} ->
        assert html =~ "Some Input"
      end)
    end

    test "does not render the label if no input was given" do
      marker = Benchee.Benchmark.no_input()

      %Benchee.Suite{
        scenarios: [
          %Benchee.Benchmark.Scenario{
            job_name: "My Job",
            name: "My Job",
            run_times: [190, 200, 210],
            input_name: marker,
            input: marker,
            run_time_statistics: %Benchee.Statistics{
              average: 200.0,
              ips: 5000.0,
              std_dev: 20,
              std_dev_ratio: 0.1,
              std_dev_ips: 500,
              median: 190.0,
              sample_size: 3,
              minimum: 190,
              maximum: 210
            }
          }
        ],
        system: @system_info
      }
      |> HTML.format(@default_options)
      |> Enum.each(fn {_, html} ->
        refute html =~ "#{marker}"
        refute html =~ "input-label"
      end)
    end
  end

  describe "write/2" do
    test "does not copy assets when inlining is on" do
      options = %{file: @filename, auto_open: false, inline_assets: true}

      capture_io(fn ->
        @sample_suite
        |> HTML.format(options)
        |> HTML.write(options)
      end)

      assert File.exists?(@expected_filename)

      content = File.read!(@expected_filename)
      assets_inlined(content, ["<style>", "<script>"])

      refute File.exists?("#{@test_directory}/assets/stylesheets/benchee.css")
      refute File.exists?("#{@test_directory}/assets/fontello/css/fontello.css")

      refute File.exists?("#{@test_directory}/assets/javascripts/benchee.js")
      refute File.exists?("#{@test_directory}/assets/javascripts/plotly-1.30.1.min.js")
    after
      if File.exists?(@test_directory), do: File.rm_rf!(@test_directory)
    end
  end

  defp comparison_and_job_htmls(
         suite \\ @sample_suite,
         options \\ %{html: %{file: @filename, auto_open: false}}
       ) do
    assert %{
             ["Some Input", "comparison"] => comparison_html,
             ["run_time", "Some Input", "My Job"] => run_time_html,
             ["memory", "Some Input", "My Job"] => memory_html
           } = HTML.format(suite, options)

    [comparison_html, run_time_html, memory_html]
  end

  defp assert_includes(html, expected_contents) do
    Enum.each(expected_contents, fn expected_content ->
      assert html =~ expected_content
    end)
  end

  defp assets_inlined(html, assets) do
    Enum.each(assets, fn asset ->
      assert html =~ asset
    end)
  end
end
