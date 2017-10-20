defmodule Benchee.Formatters.HTMLIntegrationTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @test_directory "test_output"
  @file_path "#{@test_directory}/my.html"
  @comparison_path "#{@test_directory}/my_comparison.html"

  @default_test_directory "benchmark_output"
  @default_file_path "#{@default_test_directory}/my.html"
  @default_auto_open true
  @default_comparison_path "#{@default_test_directory}/my_comparison.html"
  @expected_open_report_output ~r/Opened report using (open|xdg-open|explorer)/

  test "works just fine" do
    benchee_options = [time: 0.01, 
                      warmup: 0.02, 
                      formatters: [&Benchee.Formatters.HTML.output/1], 
                      formatter_options: [html: [file: @file_path, auto_open: false]]]

    assertion_data = %{comparison_path: @comparison_path, 
                      test_directory: @test_directory, 
                      file_path: @file_path, auto_open: false}

    basic_test(benchee_options, assertion_data)
  end

  test "works fine with the legacy format" do
    benchee_options = [time: 0.01, 
                      warmup: 0.02, 
                      formatters: [&Benchee.Formatters.HTML.output/1], 
                      html: [file: @file_path, auto_open: false]]

    assertion_data = %{comparison_path: @comparison_path, 
                      test_directory: @test_directory, 
                      file_path: @file_path, auto_open: false}

    basic_test(benchee_options, assertion_data)
  end

  test "works fine with filename not provided" do
    benchee_options = [time: 0.01, 
                      warmup: 0.02, 
                      formatters: [&Benchee.Formatters.HTML.output/1]]

    assertion_data = %{comparison_path: @default_comparison_path, 
                      test_directory: @default_test_directory, 
                      file_path: @default_file_path, auto_open: @default_auto_open}

    basic_test(benchee_options, assertion_data)
  end

  defp basic_test(benchee_options, assertion_data) do
    try do
      out = capture_io fn ->
        Benchee.run %{
          "Sleep"        => fn -> :timer.sleep(10) end,
          "Sleep longer" => fn -> :timer.sleep(20) end
        }, benchee_options

        assert File.exists?(assertion_data.comparison_path)
        assert File.exists?("#{assertion_data.test_directory}/my_sleep.html")
        assert File.exists?("#{assertion_data.test_directory}/my_sleep_longer.html")
        assert File.exists?(assertion_data.file_path)
        html = File.read! assertion_data.comparison_path

        assert html =~ "<body>"
        assert html =~ "Sleep"
        assert html =~ "Sleep longer"
        assert html =~ "ips-comparison"
      end
      if assertion_data.auto_open, do: assert out =~ @expected_open_report_output
    after
      if File.exists?(assertion_data.test_directory), do: File.rm_rf! assertion_data.test_directory
    end
  end
end
