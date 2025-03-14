defmodule LocalHexdocs do

  @moduledoc """
  You have three options for choosing libraries whose documentation you wish to save locally:
    * You can use the existing `default_libraries.txt` as is. This will save ALL those libraries'
      documentation to your local computer
    * You can modify `default_libraries.txt` and make it your own. You can add additional libraries
      and/or remove libraries by either deleting them or commenting them out with a leading "#"
  """

  @mix_path :os.cmd(~c(which mix)) |> Path.expand() |> String.trim()

  def libraries do
    "default_libraries.txt"
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&is_nil(&1))
      |> Enum.reject(& &1 == "")
      |> Enum.reject(& String.starts_with?(&1, "#"))
  end

  def fetch_all do
    stream =
      libraries()
      |> Task.async_stream(fn lib -> :os.cmd(~c(#{@mix_path} hex.docs fetch #{lib})) end)

    # {:ok, ~c"Docs already fetched: /home/mateusz/.hex/docs/hexpm/mox/1.2.0\n"}
    # {:ok, ~c"Docs fetched: /home/mateusz/.hex/docs/hexpm/paginator/1.2.0\n"}
    Enum.each(stream, fn resp -> IO.inspect(resp) end)
  end

end
