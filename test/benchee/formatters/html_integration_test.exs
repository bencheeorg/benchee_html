defmodule Benchee.Formatters.HTMLIntegrationTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @test_directory "test_output"
  @base_name "my"
  @index_path "#{@test_directory}/#{@base_name}.html"
  @comparison_path "#{@test_directory}/#{@base_name}_comparison.html"

  @default_test_directory "benchmarks/output"
  @default_base_name "results"
  @default_index_path "#{@default_test_directory}/#{@default_base_name}.html"
  @default_comparison_path "#{@default_test_directory}/#{@default_base_name}_comparison.html"

  test "works just fine" do
    benchee_options = [
      time: 0.01,
      memory_time: 0.01,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, file: @index_path, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @comparison_path,
      test_directory: @test_directory,
      index_path: @index_path,
      base_name: @base_name
    }

    basic_test(benchee_options, assertion_data, run_time: true)
  end

  test "works fine with filename not provided" do
    benchee_options = [
      time: 0.01,
      memory_time: 0.01,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @default_comparison_path,
      test_directory: @default_test_directory,
      index_path: @default_index_path,
      base_name: @default_base_name
    }

    basic_test(benchee_options, assertion_data, run_time: true)
  end

  test "works fine running only run time" do
    benchee_options = [
      time: 0.01,
      memory_time: 0,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, file: @index_path, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @comparison_path,
      test_directory: @test_directory,
      index_path: @index_path,
      base_name: @base_name
    }

    basic_test(benchee_options, assertion_data, run_time: true)
  end

  test "works fine running only memory" do
    benchee_options = [
      time: 0,
      memory_time: 0.01,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, file: @index_path, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @comparison_path,
      test_directory: @test_directory,
      index_path: @index_path,
      base_name: @base_name
    }

    basic_test(benchee_options, assertion_data, run_time: false)
  end

  test "works just fine using sequential_output" do
    benchee_options = [
      time: 0.01,
      memory_time: 0.01,
      warmup: 0.02,
      formatters: [
        fn suite ->
          Benchee.Formatters.HTML.sequential_output(suite, file: @index_path, auto_open: false)
        end
      ]
    ]

    assertion_data = %{
      comparison_path: @comparison_path,
      test_directory: @test_directory,
      index_path: @index_path,
      base_name: @base_name
    }

    basic_test(benchee_options, assertion_data, run_time: true)
  end

  test "doesn't crash if we're essentially measuring nothing" do
    capture_io(fn ->
      assert %Benchee.Suite{} =
               Benchee.run(
                 %{
                   "Sleep" => fn -> :timer.sleep(10) end
                 },
                 time: 0,
                 warmup: 0,
                 formatters: [{Benchee.Formatters.HTML, auto_open: false}]
               )
    end)
  end

  defp basic_test(benchee_options, assertion_data, options) do
    capture_io(fn ->
      Benchee.run(
        %{
          "Sleep" => fn -> :timer.sleep(10) end,
          "List" => fn -> [:rand.uniform()] end
        },
        benchee_options
      )

      assert File.exists?(assertion_data.comparison_path)
      sleep_path = "#{assertion_data.test_directory}/#{assertion_data.base_name}_sleep.html"

      assert File.exists?(sleep_path)

      list_path = "#{assertion_data.test_directory}/#{assertion_data.base_name}_list.html"
      assert File.exists?(list_path)

      assert File.exists?(assertion_data.index_path)
      comparison_html = File.read!(assertion_data.comparison_path)

      assert comparison_html =~ "<body>"
      assert comparison_html =~ "Sleep"
      assert comparison_html =~ "List"

      if Keyword.get(options, :run_time, false) do
        assert comparison_html =~ "ips-comparison"
      end

      assert comparison_html =~ "System info</a>"
      assert comparison_html =~ "benchee version"
      assert comparison_html =~ "benchee_html version"

      index_html = File.read!(assertion_data.index_path)
      assert index_html =~ ~r/href="#{Path.basename(sleep_path)}"/
      assert index_html =~ ~r/href="#{Path.basename(list_path)}"/
    end)
  after
    if File.exists?(assertion_data.test_directory), do: File.rm_rf!(assertion_data.test_directory)
  end
end
