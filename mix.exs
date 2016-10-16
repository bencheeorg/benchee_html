defmodule BencheePlotlyJS.Mixfile do
  use Mix.Project

  def project do
    [app: :benchee_plotly_js,
     version: "0.1.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
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
      {:benchee,      "~> 0.5"},
      {:benchee_json, "~> 0.1", git: "git@github.com:PragTob/benchee_json.git"}
    ]
  end

  defp package do
  [
    files: ["priv", "lib", "mix.exs", "README.md"],
    maintainers: ["Tobias Pfeiffer"],
    licenses: ["MIT"],
    links: %{
      "github"     => "https://github.com/PragTob/benchee_plotly_js",
      "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
    }
  ]
end
end
