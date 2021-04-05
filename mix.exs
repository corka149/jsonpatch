defmodule Jsonpatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpatch,
      name: "Jsonpatch",
      description: "Implementation of RFC 6902 in pure Elixir",
      version: "0.11.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      source_url: "https://github.com/corka149/jsonpatch",
      preferred_cli_env: [muzak: :test],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # REQUIRED

      # DEV
      ## testing with real json files
      {:poison, "~> 4.0", only: [:test]},
      ## code test coverage
      {:excoveralls, "~> 0.14.0", only: [:test]},
      ## linting
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false},
      ## type checking
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      ## Docs
      {:ex_doc, "~> 0.22.1", only: [:dev], runtime: false},
      ## Mutation testing
      {:muzak, "~> 1.1.0", only: :mutation}
    ]
  end

  defp package() do
    [
      maintainers: ["Sebastian Ziemann"],
      licenses: ["MIT"],
      source_url: "https://github.com/corka149/jsonpatch",
      links: %{
        "GitHub" => "https://github.com/corka149/jsonpatch"
      }
    ]
  end
end
