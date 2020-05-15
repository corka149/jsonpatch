defmodule Jsonpatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpatch,
      version: "0.3.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
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
      {:poison, "~> 3.1"},

      # DEV
      ## code test coverage
      {:excoveralls, "~> 0.12.3", only: [:test]},
      ## linting
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      ## type checking
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false}
    ]
  end
end
