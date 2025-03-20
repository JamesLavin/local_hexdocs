Code.require_file("../local_hexdocs.ex")
Code.ensure_loaded(LocalHexdocs)

ExUnit.start()
import ExUnit.CaptureIO
require Logger

defmodule LocalDocsTest do
  use ExUnit.Case, async: false

  test "LocalDocs knows it's running in test mode" do
    assert LocalHexdocs.running_tests?()
  end

  test "this works" do
    content = "does_not_exist\nnot_a_real_package"
    filepath = "./packages/my_packages"
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

  def create_file(filepath, content) when is_binary(filepath) and is_binary(content) do
    filepath
    |> Path.expand()
    |> File.write!(content)
  end

  def delete_file(filepath) do
    filepath
    |> Path.expand()
    |> File.rm!()
  end
end
