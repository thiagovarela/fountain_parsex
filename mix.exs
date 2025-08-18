defmodule FountainParsex.MixProject do
  use Mix.Project

  def project do
    [
      name: "FountainParsex",
      app: :fountain_parsex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A fountain screenplay parser"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thiagovarela/fountain_parsex"}
    ]
  end
end
