defmodule LocalHexdocs.MixProject do
  use Mix.Project

  def project do
    [
      app: :local_hexdocs,
      version: "0.1.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:recursive_selective_match, only: :test}
    ]
  end
end
