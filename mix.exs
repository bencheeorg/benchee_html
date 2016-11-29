defmodule BencheeHTML.Mixfile do
  use Mix.Project

  @version "0.1.0"
  def project do
    [
      app: :benchee_html,
      version: @version,
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [source_ref: @version],
      deps: deps(),
      package: package(),
      name: "benchee_html",
      source_url: "https://github.com/PragTob/benchee_html",
      description: """
      HTML formatter with pretty graphs for the (micro) benchmarking library benchee.
      """
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
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
      {:benchee,        "~> 0.6", git: "git@github.com:PragTob/benchee.git"},
      {:benchee_json,   "~> 0.1", git: "git@github.com:PragTob/benchee_json.git"},
      {:mix_test_watch, "~> 0.2",   only: :dev},
      {:credo,          "~> 0.4",   only: :dev},
      {:ex_doc,         "~> 0.11",  only: :dev},
      {:earmark,        "~> 1.0.1", only: :dev}
    ]
  end

  defp package do
    [
      files: ["priv", "lib", "mix.exs", "README.md"],
      maintainers: ["Tobias Pfeiffer"],
      licenses: ["MIT"],
      links: %{
        "github"     => "https://github.com/PragTob/benchee_html",
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
      }
    ]
  end
end
