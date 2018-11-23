defmodule Benchee.Formatters.HTMLIntegrationTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @test_directory "test_output"
  @base_name "my"
  @file_path "#{@test_directory}/#{@base_name}.html"
  @comparison_path "#{@test_directory}/#{@base_name}_comparison.html"

  @default_test_directory "benchmarks/output"
  @default_base_name "results"
  @default_file_path "#{@default_test_directory}/#{@default_base_name}.html"
  @default_comparison_path "#{@default_test_directory}/#{@default_base_name}_comparison.html"

  test "works just fine" do
    benchee_options = [
      time: 0.01,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, file: @file_path, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @comparison_path,
      test_directory: @test_directory,
      file_path: @file_path,
      base_name: @base_name
    }

    basic_test(benchee_options, assertion_data)
  end

  test "works fine with filename not provided" do
    benchee_options = [
      time: 0.01,
      warmup: 0.02,
      formatters: [{Benchee.Formatters.HTML, auto_open: false}]
    ]

    assertion_data = %{
      comparison_path: @default_comparison_path,
      test_directory: @default_test_directory,
      file_path: @default_file_path,
      base_name: @default_base_name
    }

    basic_test(benchee_options, assertion_data)
  end

  defp basic_test(benchee_options, assertion_data) do
    capture_io(fn ->
      Benchee.run(
        %{
          "Sleep" => fn -> :timer.sleep(10) end,
          "Sleep longer" => fn -> :timer.sleep(20) end
        },
        benchee_options
      )

      assert File.exists?(assertion_data.comparison_path)

      assert File.exists?(
               "#{assertion_data.test_directory}/#{assertion_data.base_name}_sleep.html"
             )

      assert File.exists?(
               "#{assertion_data.test_directory}/#{assertion_data.base_name}_sleep_longer.html"
             )

      assert File.exists?(assertion_data.file_path)
      html = File.read!(assertion_data.comparison_path)

      assert html =~ "<body>"
      assert html =~ "Sleep"
      assert html =~ "Sleep longer"
      assert html =~ "ips-comparison"
      assert html =~ "System info</a>"
      assert html =~ "benchee version"
      assert html =~ "benchee_html version"
    end)
  after
    if File.exists?(assertion_data.test_directory), do: File.rm_rf!(assertion_data.test_directory)
  end
end
