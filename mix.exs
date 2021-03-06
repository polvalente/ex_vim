defmodule ExVim.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_vim,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExVim.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ratatouille, "~> 0.5.1"},
      {:nimble_parsec, "~> 1.2.1"}
    ]
  end
end
