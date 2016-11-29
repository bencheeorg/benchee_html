defmodule Benchee.Formatters.HTMLTest do
  use ExUnit.Case
  alias Benchee.Formatters.HTML
  import ExUnit.CaptureIO

  @test_directory "test_output"
  @filename "#{@test_directory}/my.html"
  @expected_filename "#{@test_directory}/my_some_input.html"
  @sample_suite %{
                  config: %{html: %{file: @filename}},
                  statistics: %{
                    "Some Input" => %{
                      "My Job" => %{
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
                  },
                  run_times: %{"Some Input" => %{"My Job" => [190, 200, 210]}},
                  system: %{elixir: "1.4.0", erlang: "19.1"}
                }
  test ".format returns an HTML-ish string" do
    %{"Some Input" => html} = HTML.format @sample_suite
    assert html =~ ~r/<html>.+<script>.+<\/html>/si
  end

  test ".format has the important suite data in the html result" do
    %{"Some Input" => html} = HTML.format @sample_suite

    assert_includes html,
      ["[190,200,210]", "\"average\":200.0", "\"median\":190.0","\"ips\":5.0e3",
       "My Job", ">3<", ">190<", ">210<"]

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

  test ".format includes the elixir and erlang version" do
    %{"Some Input" => html} = HTML.format @sample_suite

    assert html =~ "Elixir 1.4.0"
    assert html =~ "Erlang 19.1"
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
    assert File.exists? "#{@test_directory}/assets/javascripts/plotly-1.20.5.min.js"
  end
end
