defmodule LocalHexdocs do

  @moduledoc """
  You have three options for choosing libraries whose documentation you wish to save locally:
    * You can use the existing `default_libraries.txt` as is. This will save ALL those libraries'
      documentation to your local computer
    * You can modify `default_libraries.txt` and make it your own. You can add additional libraries
      and/or remove libraries by either deleting them or commenting them out with a leading "#"
    * You can create your own `libraries.txt` file in the main directory with any libraries in it
      that you wish to include, and this file will be used instead of `default_libraries.txt`.
      `libraries.txt` is included in `.gitignore`, so you should be able to safely modify your
      file and have it persist across Git updates.
  """

  @timeout_ms 30_000

  # TODO: Handle response: "Couldn't find docs for package with name cqerl or version 2.1.3"

  # TODO: Sort libraries before displaying them?

  # TODO: Convert "amqp_client/4.0.3" to "amqp_client (4.0.3)"

  @mix_path :os.cmd(~c(which mix)) |> Path.expand() |> String.trim()

  def desired_libraries do
    libraries_file()
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&is_nil(&1))
      |> Enum.reject(& &1 == "")
      |> Enum.reject(& String.starts_with?(&1, "#"))
      # |> Enum.take(10)
  end

  def fetch_all do
    stream =
      desired_libraries()
      |> Task.async_stream(fn lib -> :os.cmd(~c(#{@mix_path} hex.docs fetch #{lib})) end, timeout: @timeout_ms)

    # {:ok, ~c"** (Mix) No package with name made_up_library\n"}
    # {:ok, ~c"Docs already fetched: /home/mateusz/.hex/docs/hexpm/mox/1.2.0\n"}
    # {:ok, ~c"Docs fetched: /home/mateusz/.hex/docs/hexpm/paginator/1.2.0\n"}
    stream
    |> Stream.each(fn {:ok, charlist} -> charlist |> to_string() |> String.trim() |> String.replace("** (Mix) ", "") |> IO.inspect() end)
    |> Enum.to_list()
    |> process_list()
    |> IO.inspect(limit: :infinity, printable_limit: :infinity)
    # |> dbg()
  end

  defp libraries_file do
    ["libraries.txt", "default_libraries.txt"]
    |> Enum.find(fn file -> Path.join(File.cwd!(), file) |> File.exists?() end)
    |> Path.expand()
  end

  defp process_list(list) when is_list(list) do
    base_map = %{"Docs already fetched" => [], "Docs fetched" => [], "No package with name" => []}

    list
    |> Enum.map(&convert_response/1)
    |> Enum.group_by(&List.first/1)
    |> (fn grouped -> Map.merge(base_map, grouped) end).()
    |> Map.update!("Docs already fetched", fn list -> Enum.map(list, &List.last/1) |> Enum.map(&String.split(&1, "/hexpm/")) |> Enum.map(&List.last/1) end)
    |> Map.update!("Docs fetched", fn list -> Enum.map(list, &List.last/1) |> Enum.map(&String.split(&1, "/hexpm/")) |> Enum.map(&List.last/1) end)
    |> Map.update!("No package with name", fn list -> Enum.map(list, &List.last/1) end)
  end

  defp convert_response({:ok, ~c"** (Mix) No package with name " ++ package_name}) do
    package_name = package_name |> to_string() |> String.trim()
    ["No package with name", package_name]
  end

  defp convert_response({:ok, charlist}) when is_list(charlist) do
    charlist
    |> to_string()
    |> String.trim()
    |> String.split(": ")
  end

  # IMPROVE
  def downloaded_libraries do
  end

  # IMPROVE
  def missing_libraries do
  end
end
