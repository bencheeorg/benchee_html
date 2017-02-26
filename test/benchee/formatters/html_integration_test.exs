defmodule Benchee.Formatters.HTMLIntegrationTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @test_directory "test_output"
  @file_path "#{@test_directory}/my.html"
  @comparison_path "#{@test_directory}/my_comparison.html"
  test "works just fine" do
    try do
      capture_io fn ->
        Benchee.run %{
          "Sleep"        => fn -> :timer.sleep(10) end,
          "Sleep longer" => fn -> :timer.sleep(20) end
        },
        time: 0.01,
        warmup: 0.02,
        formatters: [&Benchee.Formatters.HTML.output/1],
        html: %{file: @file_path}

        assert File.exists?(@comparison_path)
        assert File.exists?("#{@test_directory}/my_sleep.html")
        assert File.exists?("#{@test_directory}/my_sleep_longer.html")
        assert File.exists?(@file_path)
        html = File.read! @comparison_path

        assert html =~ "<body>"
        assert html =~ "Sleep"
        assert html =~ "Sleep longer"
        assert html =~ "ips-comparison"
      end
    after
      if File.exists?(@test_directory), do: File.rm_rf! @test_directory
    end
  end

end
