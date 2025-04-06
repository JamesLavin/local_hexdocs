defmodule LocalHexdocs.MixProject do
  use Mix.Project

  def project do
    [
      app: :local_hexdocs,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:recursive_selective_match, only: :test}
    ]
  end
end
