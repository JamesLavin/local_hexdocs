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

  See [README.md](https://github.com/JamesLavin/local_hexdocs/blob/main/README.md) for more details
  """
  Code.ensure_loaded!(LocalHexdocs.Helpers)

  import LocalHexdocs.Helpers

  # Number of parallel threads used to pull documentation. The higher this number,
  # the greater the load placed on `hexdocs.pm` and the greater your odds of getting rate limited
  @max_concurrency 1

  @timeout_ms 30_000

  @hex_home (if(running_tests?()) do
               "./test/.hex"
             else
               "~/.hex"
             end)

  # default `HEX_HOME` is ~/.hex
  # `HEX_HOME` can be overridden
  @mix_path :os.cmd(~c(which mix)) |> Path.expand() |> String.trim()

  @doc """
  Generates a list of package names with downloaded Hexdocs doc files.

  Called by `local_docs.exs list`
  """
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

  @doc """
  Finds all LocalHexdocs configuration files, generates and de-duplicates a list of all packages in the config
  files, and then fetches each -- one by one to avoid overloading the Hexdocs.pm server or triggering rate limiting.
  Saves each package's Hexdocs files in a directory like `~/.hex/docs/hexpm/`.

  Called by `local_docs.exs get`
  """
  def fetch_all do
      desired_packages()

    stream =
      desired_packages()
      |> Task.async_stream(
        fn lib -> :os.cmd(~c(HEX_HOME=#{@hex_home} #{@mix_path} hex.docs fetch #{lib})) end,
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

  @doc """
  Generates a list of package names with downloaded Hexdocs doc files, each with a list of all
  downloaded package versions.

  Called by `local_docs.exs versions`
  """
  def display_downloaded_packages_with_versions do
    downloaded_packages_with_versions()
    |> IO.inspect(
      label: "Packages downloaded in #{hexpm_dir()}",
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  @doc """
  Finds all Hexdocs packages with multiple versions, then builds and outputs a data structure for each,
  specifying the most recent package version, which it will retain, and the others, which `clean` would
  remove.

  Called by `local_docs.exs to_clean`
  """
  def display_package_versions_to_remove do
    package_versions_to_remove()
    |> IO.inspect(
      label: "Packages with multiple Hexdocs versions in #{hexpm_dir()}",
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  @doc """
  Frees up disk space by deleting all but the most recent Hexdocs version of all packages with
  multiple downloaded versions.

  Operates on data structure generated by `elixir local_docs.exs to_clean`, which looks like:
    [ %{delete: ["1.7.8"], keep: "1.7.9", package: "absinthe"},
      %{delete: ["2.15.1"], keep: "2.15.2", package: "appsignal"} ]

  We recommend you run `to_clean` and inspect the output before running `clean`. But if anything
  ever goes wrong, you can always just re-download all your packages with `local_docs.exs get`.

  Called by `local_docs.exs to_clean`
  """
  def remove_stale_versions do
    package_versions_to_remove()
    |> Enum.each(&delete_older_versions/1)
  end

  @doc """
  Finds and displays all packages with multiple Hexdocs versions

  Called by `local_docs.exs multiple_versions`
  """
  def display_downloaded_packages_with_multiple_versions do
    downloaded_packages_with_multiple_versions()
    |> IO.inspect(
      label: "Packages downloaded in #{hexpm_dir()} with multiple versions",
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  def packages_dir do
    if running_tests?() do
      "./test/packages"
    else
    "./packages"
    end
  end

  def packages_files do
    packages_dir = packages_dir()

    case Path.expand(packages_dir) |> File.ls() do
      {:ok, []} ->
        packages_file()

      {:ok, user_files} ->
        user_files |> Enum.map(fn filename -> Path.join(packages_dir(), filename) end)

      {:error, _err} ->
        packages_file()
    end
  end

  defp package_name_plus_versions(name) do
    {name |> String.to_atom(), package_versions(name)}
  end

  defp delete_older_versions(%{
         package: _package_name,
         delete: _versions_to_delete,
         keep: _keep,
         delete_dirs: delete_dirs
       })
       when is_list(delete_dirs) do
    delete_dirs
    |> Enum.each(fn dir ->
      IO.inspect("Deleting #{dir}")
      File.rm_rf!(dir)
    end)
  end

  defp path_to_version(package_name, version_string)
       when is_binary(package_name) and is_binary(version_string) do
    hexpm_dir()
    |> Path.join([package_name, "/", version_string])
  end

  defp package_versions_to_remove do
    grab_package_name = fn {package_name, _versions} -> package_name end

    downloaded_packages_with_multiple_versions()
    |> Enum.map(grab_package_name)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.map(&versions_to_keep_and_delete/1)
  end

  defp versions_to_keep_and_delete(package_name) do
    versions =
      package_name
      |> package_versions()

    latest =
      versions
      |> latest_version()

    delete_vers = versions -- [latest]

    delete_dirs = delete_vers |> Enum.map(&path_to_version(package_name, &1))

    %{package: package_name, keep: latest, delete: delete_vers, delete_dirs: delete_dirs}
  end

  defp downloaded_packages_with_versions do
    hexpm_dir()
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(&package_name_plus_versions/1)
  end

  defp downloaded_packages_with_multiple_versions do
    downloaded_packages_with_versions()
    |> Enum.filter(fn {_name, versions} -> length(versions) > 1 end)
  end

  defp latest_version(list_of_version_strings) do
    list_of_version_strings
    |> Enum.map(&version_string_to_int_list/1)
    |> Enum.reduce(fn version, acc ->
      if version > acc do
        version
      else
        acc
      end
    end)
    |> int_list_to_version_string()
  end

  # IMPROVE: This assumes version numbers are always integers. This will break if SemVer
  #          is violated, as sometimes happens with pre-release version names.
  defp version_string_to_int_list(version_string) when is_binary(version_string) do
    version_string |> String.split(".") |> Enum.map(&String.to_integer/1)
  end

  defp int_list_to_version_string(int_list) when is_list(int_list) do
    int_list
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join(".")
  end

  defp package_versions(package_name) do
    hexpm_dir()
    |> Path.join(package_name)
    |> File.ls!()
  end

  defp desired_packages do
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

  # Use packages.txt if it exists or default_packages.txt otherwise
  defp packages_file do
    file = ["packages.txt", "default_packages.txt"]
      |> Enum.map(&Path.join(top_dir(), &1))
      |> Enum.find(&File.exists?/1)

    if file do
      file
      |> Path.expand()
      |> List.wrap()
    else
      []
    end
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
