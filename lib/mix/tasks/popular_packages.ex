defmodule Mix.Tasks.PopularPackages do
  use Mix.Task

  @shortdoc "Rebuild popular_packages.txt"

  @moduledoc """
  Fetches a list of most downloaded packages from hex.pm and stores into the
  top-level popular_packages.txt file.

  ## Usage

      mix popular_packages
  """

  @base_url "https://hex.pm/api/packages"
  @file_path File.cwd!() <> "/popular_packages.txt"
  @page_count 11

  def run([]) do
    Mix.shell().info("Fetching #{@page_count} pages of packages...")

    names = build_popular_list()
    count = length(names)

    header = """
    # The #{count} most popular packages on hex.pm, according to #{@base_url} on #{Date.utc_today() |> Date.to_string()}
    # Generated using:
    #     mix popular_packages
    """

    File.write!(@file_path, header <> Enum.join(names, "\n"))
    Mix.shell().info("Wrote #{count} package names to #{@file_path}")
  end

  defp build_popular_list() do
    1..@page_count
    |> Enum.flat_map(&fetch_page/1)
    |> Enum.map(& &1["name"])
  end

  defp fetch_page(page),
    do: api_get(@base_url <> "?sort=recent_downloads&page=#{page}")

  defp user_agent do
    mix_config = Mix.Project.config()
    to_string(mix_config[:app]) <> " " <> mix_config[:version]
  end

  defp api_get(url) do
    {:ok, {{_, 200, _}, _, body}} =
      :httpc.request(
        :get,
        {to_charlist(url),
         [
           {~c"user-agent", to_charlist(user_agent())},
           {~c"accept", ~c"application/json"}
         ]},
        [],
        []
      )

    Jason.decode!(body)
  end
end
