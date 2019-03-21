defmodule JQ.MixProject do
  use Mix.Project

  def project do
    [
      app: :jq,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "jq",
      source_url: "https://github.com/spencerdcarlson/ex_jq",
      homepage_url: "https://github.com/spencerdcarlson/ex_jq",
      docs: [
        main: "jq",
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
      {:poison, "~> 4.0"},
      {:temp, "~> 0.4"},
      {:credo, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
