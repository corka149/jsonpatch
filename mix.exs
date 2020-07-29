defmodule Jsonpatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpatch,
      name: "Jsonpatch",
      description: "Implementation of RFC 6902 in pure Elixir",
      version: "0.9.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      source_url: "https://github.com/corka149/jsonpatch"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # REQUIRED

      # DEV
      ## testing with real json files
      {:poison, "~> 3.1", only: [:test]},
      ## code test coverage
      {:excoveralls, "~> 0.12.3", only: [:test]},
      ## linting
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      ## type checking
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      ## Docs
      {:ex_doc, "~> 0.22.1", only: [:dev], runtime: false}
    ]
  end

  defp package() do
    [
      maintainers: ["Sebastian Ziemann"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/corka149/jsonpatch"
      }
    ]
  end
end
