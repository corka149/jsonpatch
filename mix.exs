defmodule Jsonpatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpatch,
      name: "Jsonpatch",
      description: "Implementation of RFC 6902 in pure Elixir",
      version: "2.0.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      source_url: "https://github.com/corka149/jsonpatch",
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        docs: :dev
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.16", only: [:test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.30", only: [:dev], runtime: false}
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
