defmodule BencheeHTML.Mixfile do
  use Mix.Project

  @source_url "https://github.com/PragTob/benchee_html"
  @version "1.0.0"

  def project do
    [
      app: :benchee_html,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      name: "benchee_html",
      test_coverage: [tool: ExCoveralls]
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
      {:excoveralls, "~> 0.10.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: """
      HTML formatter with pretty graphs for the (micro) benchmarking library benchee.
      Also allows export as PNG image!
      """,
      files: ["priv", "lib", "mix.exs", "README.md"],
      maintainers: ["Tobias Pfeiffer"],
      licenses: ["MIT"],
      links: %{
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/",
        "Changelog" => "https://hexdocs.pm/benchee_html/changelog.html",
        "GitHub" =>  @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end
end
