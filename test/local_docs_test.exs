# Code.require_file("./lib/local_hexdocs.ex")
# Code.ensure_loaded(LocalHexdocs)

alias LocalHexdocs.Helpers
import ExUnit.CaptureIO
require Logger
require RecursiveSelectiveMatch, as: RSM

defmodule LocalDocsTest do
  use ExUnit.Case, async: false

  setup do
    recreate_test_hexpm_dir()
    clear_test_package_files()

    :ok
    # on_exit(fn ->
    #   clear_test_hex_packages()
    # end)
  end

  test "mix_env is set to :test" do
    assert Helpers.mix_env() == :test
  end

  test "packages_dir is set correctly for testing" do
    assert LocalHexdocs.packages_dir() == "./test/packages"
  end

  test "hexpm_dir is correct for test mode" do
    assert Helpers.hexpm_dir() == "./test/.hex/docs/hexpm" |> Path.expand()
  end

  test "LocalDocs knows it's running in test mode" do
    assert Helpers.running_tests?()
  end

  test "packages_files is set correctly when user hasn't specified any package files" do
    assert LocalHexdocs.packages_files() == ["./test/default_packages.txt" |> Path.expand()]
  end

  test "packages_files is set correctly when user has created a packages file" do
    # create test packages file in test/packages/
    content = "mix\nex_unit"
    filepath = "./test/packages/my_packages"
    create_file(filepath, content)

    assert [LocalHexdocs.packages_files() |> Path.expand()] == [filepath |> Path.expand()]

    # delete test packages file
    delete_file(filepath)
  end

  test "packages_files are set correctly when user has created two packages files" do
    # create test packages file in test/packages/
    content = "mix\nex_unit"
    filepath = "./test/packages/my_packages"
    create_file(filepath, content)

    content2 = "req\nfinch"
    filepath2 = "./test/packages/my_packages2"
    create_file(filepath2, content2)

    assert LocalHexdocs.packages_files() |> Enum.map(&Path.expand/1) |> Enum.sort() ==
             [filepath |> Path.expand(), filepath2 |> Path.expand()] |> Enum.sort()

    # delete test packages file
    delete_file(filepath)
    delete_file(filepath2)
  end

  test "gets Hexdocs for valid package names; doesn't re-fetch on 2nd get" do
    content = "elixir\nphoenix"
    filepath = "./test/packages/my_packages"
    create_file(filepath, content)

    {result, output} = with_io(fn -> LocalHexdocs.fetch_all() end)

    assert RSM.matches?(
             %{
               "Couldn't find docs" => [],
               "Docs already fetched" => [],
               "Docs fetched" => :any_list,
               "No package with name" => []
             },
             result
           )

    docs_fetched_1 = result["Docs fetched"]

    assert output =~
             "\"Docs fetched: ./test/.hex/docs/hexpm/elixir/"

    assert output =~
             "\"\n\"Docs fetched: ./test/.hex/docs/hexpm/phoenix/"

    assert output =~
             "\"\n%{\n  \"Couldn't find docs\" => [],\n  \"Docs already fetched\" => [],\n  \"Docs fetched\" => [\"elixir/"

    assert output =~
             "\", \"phoenix/"

    assert output =~
             "\"],\n  \"No package with name\" => []\n}\n"

    assert LocalHexdocs.downloaded_packages() == ["elixir", "phoenix"]

    assert [{:elixir, [elixir_version]}, {:phoenix, [phoenix_version]}] =
             LocalHexdocs.display_downloaded_packages_with_versions()

    assert docs_fetched_1 == ["elixir/#{elixir_version}", "phoenix/#{phoenix_version}"]

    {result2, output2} = with_io(fn -> LocalHexdocs.fetch_all() end)

    assert RSM.matches?(
             %{
               "Couldn't find docs" => [],
               "Docs already fetched" => :any_list,
               "Docs fetched" => [],
               "No package with name" => []
             },
             result2
           )

    assert docs_fetched_1 == result2["Docs already fetched"]

    assert output2 ==
             "\"Docs already fetched: ./test/.hex/docs/hexpm/elixir/#{elixir_version}\"\n\"Docs already fetched: ./test/.hex/docs/hexpm/phoenix/#{phoenix_version}\"\n%{\n  \"Couldn't find docs\" => [],\n  \"Docs already fetched\" => [\"elixir/#{elixir_version}\", \"phoenix/#{phoenix_version}\"],\n  \"Docs fetched\" => [],\n  \"No package with name\" => []\n}\n"

    assert [{:elixir, [^elixir_version]}, {:phoenix, [^phoenix_version]}] =
             LocalHexdocs.display_downloaded_packages_with_versions()

    assert [] = LocalHexdocs.display_package_versions_to_remove()

    delete_file(filepath)
  end

  test "display_package_versions_to_remove" do
    dirs = [
      "./test/.hex/docs/hexpm/elixir/0.1.1",
      "./test/.hex/docs/hexpm/elixir/1.1.1",
      "./test/.hex/docs/hexpm/elixir/1.2.1",
      "./test/.hex/docs/hexpm/elixir/1.2.3",
      "./test/.hex/docs/hexpm/elixir/2.0.4",
      "./test/.hex/docs/hexpm/elixir/2.1.2",
      "./test/.hex/docs/hexpm/elixir/2.1.1"
    ]

    dirs |> Enum.each(&File.mkdir_p/1)

    expected_result = [
      %{
        delete: ["0.1.1", "1.1.1", "1.2.1", "1.2.3", "2.0.4", "2.1.1"],
        keep: "2.1.2",
        package: "elixir",
        delete_dirs: [
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/0.1.1",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.1.1",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.2.1",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.2.3",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/2.0.4",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/2.1.1"
        ]
      }
    ]

    expected_output =
      "Packages with multiple Hexdocs versions in /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm: [\n  %{\n    delete: [\"0.1.1\", \"1.1.1\", \"1.2.1\", \"1.2.3\", \"2.0.4\", \"2.1.1\"],\n    keep: \"2.1.2\",\n    package: \"elixir\",\n    delete_dirs: [\"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/0.1.1\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.1.1\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.2.1\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/1.2.3\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/2.0.4\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/elixir/2.1.1\"]\n  }\n]\n"

    {result, output} = with_io(fn -> LocalHexdocs.display_package_versions_to_remove() end)

    assert result == expected_result
    assert output == expected_output
  end

  test "remove_stale_versions" do
    dirs = [
      "./test/.hex/docs/hexpm/nx/3.2.0",
      "./test/.hex/docs/hexpm/nx/3.1.99",
      "./test/.hex/docs/hexpm/nx/0.55.55",
      "./test/.hex/docs/hexpm/nx/1.1.1",
      "./test/.hex/docs/hexpm/nx/1.2.1",
      "./test/.hex/docs/hexpm/nx/1.2.3",
      "./test/.hex/docs/hexpm/nx/2.0.4",
      "./test/.hex/docs/hexpm/nx/2.11.2",
      "./test/.hex/docs/hexpm/nx/2.1.1"
    ]

    dirs |> Enum.each(&File.mkdir_p/1)

    expected_result = [
      %{
        delete: ["3.1.99", "0.55.55", "1.1.1", "1.2.1", "1.2.3", "2.0.4", "2.11.2", "2.1.1"],
        delete_dirs: [
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/3.1.99",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/0.55.55",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.1.1",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.1",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.3",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.0.4",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.11.2",
          "/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.1.1"
        ],
        keep: "3.2.0",
        package: "nx"
      }
    ]

    expected_output =
      "Packages with multiple Hexdocs versions in /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm: [\n  %{\n    delete: [\"3.1.99\", \"0.55.55\", \"1.1.1\", \"1.2.1\", \"1.2.3\", \"2.0.4\", \"2.11.2\",\n     \"2.1.1\"],\n    keep: \"3.2.0\",\n    package: \"nx\",\n    delete_dirs: [\"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/3.1.99\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/0.55.55\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.1.1\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.1\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.3\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.0.4\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.11.2\",\n     \"/home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.1.1\"]\n  }\n]\n"

    {result, output} = with_io(fn -> LocalHexdocs.display_package_versions_to_remove() end)

    assert result == expected_result
    assert output == expected_output

    {result2, output2} = with_io(fn -> LocalHexdocs.remove_stale_versions() end)

    expected_result2 = :ok

    expected_output2 =
      "\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/3.1.99\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/0.55.55\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.1.1\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.1\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/1.2.3\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.0.4\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.11.2\"\n\"Deleting /home/mateusz/Git/local_hexdocs/test/.hex/docs/hexpm/nx/2.1.1\"\n"

    assert result2 == expected_result2
    assert output2 == expected_output2

    {result3, output3} =
      with_io(fn -> LocalHexdocs.display_downloaded_packages_with_versions() end)

    assert result3 == [nx: ["3.2.0"]]
    assert output3 == "Packages downloaded in #{Helpers.hexpm_dir()}: [nx: [\"3.2.0\"]]\n"
  end

  test "handles invalid package names" do
    content = "does_not_exist\nnot_a_real_package"
    filepath = "./test/packages/my_packages"
    create_file(filepath, content)

    {result, output} = with_io(fn -> LocalHexdocs.fetch_all() end)

    assert result ==
             %{
               "Couldn't find docs" => [],
               "Docs already fetched" => [],
               "Docs fetched" => [],
               "No package with name" => ["does_not_exist", "not_a_real_package"]
             }

    assert output ==
             "\"No package with name does_not_exist\"\n\"No package with name not_a_real_package\"\n%{\n  \"Couldn't find docs\" => [],\n  \"Docs already fetched\" => [],\n  \"Docs fetched\" => [],\n  \"No package with name\" => [\"does_not_exist\", \"not_a_real_package\"]\n}\n"

    delete_file(filepath)
  end

  @tag :skip
  test "ignores non-numeric package versions (that don't follow semantic versioning)" do
  end

  def recreate_test_hexpm_dir do
    clear_test_hexpm_dir()
    create_test_hexpm_dir()
  end

  def create_test_hexpm_dir do
    "./test/.hex/docs/hexpm"
    |> Path.expand()
    |> File.mkdir_p()
  end

  def clear_test_hexpm_dir do
    "./test/.hex/docs/hexpm"
    |> Path.expand()
    |> File.rm_rf()
  end

  def clear_test_package_files do
    "./test/packages/*"
    |> Path.expand()
    |> File.rm()
  end

  def create_file(filepath, content) when is_binary(filepath) and is_binary(content) do
    abs_filepath = filepath |> Path.expand()

    if File.exists?(abs_filepath) do
      File.rm!(abs_filepath)
    end

    abs_filepath
    |> File.write!(content)
  end

  def delete_file(filepath) do
    filepath
    |> Path.expand()
    |> File.rm!()
  end
end
