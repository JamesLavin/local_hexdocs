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

  test "packages_dir is set correctly" do
    assert LocalHexdocs.packages_dir() == "./test/packages"
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

    assert LocalHexdocs.packages_files |> Enum.map(&Path.expand/1) |> Enum.sort() == [filepath |> Path.expand(), filepath2 |> Path.expand()] |> Enum.sort()

    # delete test packages file
    delete_file(filepath)
    delete_file(filepath2)
  end

  test "hexpm_dir is correct for test mode" do
    assert Helpers.hexpm_dir == "./test/.hex/docs/hexpm" |> Path.expand()
  end

  test "LocalDocs knows it's running in test mode" do
    assert Helpers.running_tests?()
  end

  test "gets Hexdocs for valid package names" do
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
             }, result)

    assert result["Docs fetched"] == ["elixir/1.17.3", "phoenix/1.7.20"]

    assert output =~
             "\"Docs fetched: ./test/.hex/docs/hexpm/elixir/"
    assert output =~
             "\"\n\"Docs fetched: ./test/.hex/docs/hexpm/phoenix/"
    assert output =~
             "\"\n%{\n  \"Couldn't find docs\" => [],\n  \"Docs already fetched\" => [],\n  \"Docs fetched\" => [\"elixir/"
    assert output =~
             "\", \"phoenix/1.7.20\"],\n  \"No package with name\" => []\n}\n"

    assert LocalHexdocs.downloaded_packages() == ["elixir", "phoenix"]

    # assert LocalHexdocs.display_downloaded_packages_with_versions() == ["elixir", "phoenix"]

    delete_file(filepath)
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
