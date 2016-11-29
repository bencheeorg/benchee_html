defmodule Benchee.Formatters.HTMLTest do
  use ExUnit.Case
  alias Benchee.Formatters.HTML

  @test_directory "test_output"
  @filename "#{@test_directory}/my.html"
  @expected_filename "#{@test_directory}/my_some_input.html"
  @sample_suite %{
                  config: %{html: %{file: @filename}},
                  statistics: %{
                    "Some Input" => %{
                      "My Job" => %{
                        average: 200.0,
                        ips: 5000.0,
                        std_dev: 20,
                        std_dev_ratio: 0.1,
                        std_dev_ips: 500,
                        median: 190.0
                      }
                    }
                  },
                  run_times: %{"Some Input" => %{"My Job" => [190, 200, 210]}}
                }
  test ".format returns an HTML-ish string" do
    %{"Some Input" => html} = HTML.format @sample_suite
    assert html =~ ~r/<html>.+<script>.+<\/html>/si
  end

  test ".format has the important suite data in the html result" do
    %{"Some Input" => html} = HTML.format @sample_suite

    assert_includes html, ["[190,200,210]", "\"average\":200.0",
                           "\"median\":190.0","\"ips\":5.0e3", "My Job"]

  end

  test ".format produces the right JSON data without the input level" do
    %{"Some Input" => html} = HTML.format @sample_suite

    assert html =~ "{\"statistics\":{\"My Job\""
  end

  test ".format does not use ± as it breaks" do
    %{"Some Input" => html} = HTML.format @sample_suite

    refute html =~ "±"
    assert html =~ "&plusmn;"
  end

  defp assert_includes(html, expected_contents) do
    Enum.each expected_contents, fn(expected_content) ->
      assert html =~ expected_content
    end
  end

  test ".output returns the suite again unchanged" do
    try do
      return = Benchee.Formatters.HTML.output(@sample_suite)
      assert return == @sample_suite
      assert File.exists? @expected_filename
      assert_assets_copied()

      content = File.read! @expected_filename
      assert_includes content, ["My Job", "average"]
    after
      if File.exists?(@test_directory), do: File.rm_rf! @test_directory
    end
  end

  defp assert_assets_copied do
    assert File.exists? "#{@test_directory}/assets/javascripts/benchee.js"
    assert File.exists? "#{@test_directory}/assets/javascripts/plotly-1.20.5.min.js"
  end
end
