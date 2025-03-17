defmodule LocalHexdocs do
  @moduledoc """
  You have four options for choosing packages whose documentation you wish to save locally:
    * (RECOMMENDED) You can create a `/packages` subdirectory with one or more files with at
      least one row containing a package name you wish to save Hexdocs for. All package names
      (one row per package name) in all files you create in this directory will be merged and
      de-duplicated, and `LocalHexdocs` will try to pull their documentation.
    * You can do nothing and use the existing `default_packages.txt` as is. This will save ALL
      those packages' documentation to your local computer
    * You can modify `default_packages.txt` and make it your own. You can add additional packages
      and/or remove packages by either deleting them or commenting them out with a leading "#"
    * You can create your own `packages.txt` file in the main directory with any packages in it
      that you wish to include, and this file will be used instead of `default_packages.txt`.
      `packages.txt` is included in `.gitignore`, so you should be able to safely modify your
      file and have it persist across Git updates.
  """

  # Number of parallel threads used to pull documentation. The higher this number,
  # the greater the load placed on `hexdocs.pm` and the greater your odds of getting rate limited
  @max_concurrency 1

  @timeout_ms 30_000

  @mix_path :os.cmd(~c(which mix)) |> Path.expand() |> String.trim()

  defp hexpm_dir do
    "~/.hex/docs/hexpm/" |> Path.expand()
  end

  def downloaded_packages do
    hexpm_dir()
    |> File.ls!()
    |> Enum.sort()
    |> IO.inspect(
      label: "Packages downloaded in #{hexpm_dir()}",
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  def desired_packages do
    packages_files()
    |> Enum.flat_map(&extract_package_names/1)
    |> Enum.sort()
    |> Enum.uniq()

    # For testing:
    # |> Enum.take(10)
  end

  defp extract_package_names(filepath) do
    filepath
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&is_nil(&1))
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&String.starts_with?(&1, "#"))
  end

  def fetch_all do
    stream =
      desired_packages()
      |> Task.async_stream(fn lib -> :os.cmd(~c(#{@mix_path} hex.docs fetch #{lib})) end,
        timeout: @timeout_ms,
        max_concurrency: @max_concurrency
      )

    # Expected responses:
    # "Failed to retrieve package information\nAPI rate limit exceeded for IP [my IP address]\n** (MatchError) no match of right hand side value: nil\n    (hex 2.1.1) lib/mix/tasks/hex.docs.ex:135: Mix.Tasks.Hex.Docs.find_package_latest_version/2\n    (hex 2.1.1) lib/mix/tasks/hex.docs.ex:99: Mix.Tasks.Hex.Docs.fetch_docs/2\n    (mix 1.17.3) lib/mix/task.ex:495: anonymous fn/3 in Mix.Task.run_task/5\n    (mix 1.17.3) lib/mix/cli.ex:96: Mix.CLI.run_task/2\n    /home/mateusz/.asdf/installs/elixir/1.17.3-otp-27/bin/mix:2: (file)"
    # {:ok, ~c"Couldn't find docs for package with name neotoma or version 1.7.3\n"}
    # {:ok, ~c"** (Mix) No package with name made_up_library\n"}
    # {:ok, ~c"Docs already fetched: /home/mateusz/.hex/docs/hexpm/mox/1.2.0\n"}
    # {:ok, ~c"Docs fetched: /home/mateusz/.hex/docs/hexpm/paginator/1.2.0\n"}

    stream
    |> Stream.take_while(fn resp -> !rate_limited?(resp) end)
    |> Stream.each(&display_response/1)
    |> Enum.to_list()
    |> process_list()
    |> IO.inspect(limit: :infinity, printable_limit: :infinity)
  end

  defp packages_files do
    case Path.expand(".") |> Path.join("/packages") |> File.ls() do
      {:ok, []} ->
        packages_file()

      {:ok, user_files} ->
        user_files |> Enum.map(fn filename -> Path.join(Path.expand("./packages"), filename) end)

      {:error, _err} ->
        packages_file()
    end
  end

  # Use packages.txt if it exists or default_packages.txt otherwise
  defp packages_file do
    ["packages.txt", "default_packages.txt"]
    |> Enum.find(fn file -> Path.join(File.cwd!(), file) |> File.exists?() end)
    |> Path.expand()
    |> List.wrap()
  end

  defp process_list(list) when is_list(list) do
    base_map = %{
      "Couldn't find docs" => [],
      "Docs already fetched" => [],
      "Docs fetched" => [],
      "No package with name" => []
    }

    list
    |> Enum.map(&convert_response/1)
    |> Enum.group_by(&List.first/1)
    |> (fn grouped -> Map.merge(base_map, grouped) end).()
    |> Map.update!(
      "Couldn't find docs",
      &Enum.map(&1, fn [_status, package_name] -> package_name end)
    )
    |> Map.update!("Docs already fetched", &extract_package_names_from_paths/1)
    |> Map.update!("Docs fetched", &extract_package_names_from_paths/1)
    |> Map.update!(
      "No package with name",
      &Enum.map(&1, fn [_status, package_name] -> package_name end)
    )
  end

  defp extract_package_names_from_paths(list) when is_list(list) do
    list
    |> Enum.map(&extract_package_name_from_path/1)
  end

  defp extract_package_name_from_path([_status, path]) when is_binary(path) do
    path
    |> String.split("/hexpm/")
    |> List.last()
  end

  defp convert_response({:ok, ~c"** (Mix) No package with name " ++ package_name}) do
    package_name = package_name |> to_string() |> String.trim()
    ["No package with name", package_name]
  end

  defp convert_response({:ok, ~c"Couldn't find docs for package with name " ++ rest}) do
    package_name =
      rest
      |> to_string()
      |> String.trim()
      |> String.split(" ")
      |> List.first()

    ["Couldn't find docs", package_name]
  end

  defp convert_response({:ok, charlist}) when is_list(charlist) do
    charlist
    |> to_string()
    |> String.trim()
    |> String.split(": ")
  end

  defp display_response({:ok, charlist}) when is_list(charlist) do
    charlist
    |> to_string()
    |> String.trim()
    |> String.replace("** (Mix) ", "")
    |> IO.inspect()
  end

  defp rate_limited?(resp) do
    elem(resp, 0) == :ok &&
      String.match?(elem(resp, 1) |> to_string(), ~r/rate limit exceeded for IP /)
  end

  # IMPROVE
  def missing_packages do
  end
end
