defmodule LocalHexdocs do

  @moduledoc """
  You have three options for choosing libraries whose documentation you wish to save locally:
    * You can use the existing `default_libraries.txt` as is. This will save ALL those libraries'
      documentation to your local computer
    * You can modify `default_libraries.txt` and make it your own. You can add additional libraries
      and/or remove libraries by either deleting them or commenting them out with a leading "#"
  """

  @mix_path :os.cmd(~c(which mix)) |> Path.expand() |> String.trim()

  def desired_libraries do
    libraries_file()
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&is_nil(&1))
      |> Enum.reject(& &1 == "")
      |> Enum.reject(& String.starts_with?(&1, "#"))
      # |> Enum.take(5)
  end

  def fetch_all do
    stream =
      desired_libraries()
      |> Task.async_stream(fn lib -> :os.cmd(~c(#{@mix_path} hex.docs fetch #{lib})) end)

    # {:ok, ~c"Docs already fetched: /home/mateusz/.hex/docs/hexpm/mox/1.2.0\n"}
    # {:ok, ~c"Docs fetched: /home/mateusz/.hex/docs/hexpm/paginator/1.2.0\n"}
    stream
    |> Enum.to_list()
    |> process_list()
    |> IO.inspect()
  end

  defp libraries_file do
    ["libraries.txt", "default_libraries.txt"]
    |> Enum.find(fn file -> Path.join(File.cwd!(), file) |> File.exists?() end)
    |> Path.expand()
  end

  defp process_list(list) when is_list(list) do
    list
    |> Enum.map(&convert_response/1)
    |> Enum.group_by(&List.first/1)
    |> (fn grouped -> Map.merge(%{"Docs already fetched" => [], "Docs fetched" => []}, grouped) end).()
    |> Map.update!("Docs already fetched", fn list -> Enum.map(list, &List.last/1) |> Enum.map(&String.split(&1, "/hexpm/")) |> Enum.map(&List.last/1) end)
    |> Map.update!("Docs fetched", fn list -> Enum.map(list, &List.last/1) |> Enum.map(&String.split(&1, "/hexpm/")) |> Enum.map(&List.last/1) end)
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
