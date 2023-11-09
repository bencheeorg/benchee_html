defmodule BencheeHTML.Mixfile do
  use Mix.Project

  @version "1.0.0"
  def project do
    [
      app: :benchee_html,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [source_ref: @version],
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :underspecs],
        plt_file: {:no_warn, "tools/plts/benchee.plt"}
      ],
      name: "benchee_html",
      source_url: "https://github.com/PragTob/benchee_html",
      description: """
      HTML formatter with pretty graphs for the (micro) benchmarking library benchee.
      Also allows export as PNG image!
      """
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:benchee, ">= 0.99.0 and < 2.0.0"},
      {:benchee_json, "~> 1.0"},
      {:excoveralls, "~> 0.18", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 1.2", only: :dev},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["priv", "lib", "mix.exs", "README.md"],
      maintainers: ["Tobias Pfeiffer"],
      licenses: ["MIT"],
      links: %{
        "github" => "https://github.com/PragTob/benchee_html",
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
      }
    ]
  end
end
