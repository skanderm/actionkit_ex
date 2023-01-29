defmodule Actionkit.MixProject do
  use Mix.Project

  def project do
    [
      app: :actionkit,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:hackney, "~> 1.18"},
      {:httpotion, "~> 3.1.0"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.7.9"},
      {:short_maps, "~> 0.1.2"},
      {:plug, "~> 1.0"}
    ]
  end
end
