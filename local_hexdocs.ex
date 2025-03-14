
# stream = ["mock", "money"]
#   |> Task.async_stream(fn lib -> :os.cmd(~c(#{mix_path} hex.docs fetch #{lib})) end)
# 
# Enum.each(stream, fn resp -> IO.inspect(resp) end)

# exit(1)

defmodule LocalHexdocs do

  def mix_path do
    :os.cmd(~c(which mix)) |> Path.expand() |> String.trim() |> IO.inspect()
  end

  def libraries do
    "default_libraries.txt"
      |> File.read!()
      |> String.split("\n")
      |> Enum.reject(&is_nil(&1))
      |> Enum.reject(& &1 == "")
  end

  def fetch_all do
    stream =
      libraries()
      |> Task.async_stream(fn lib -> :os.cmd(~c(#{mix_path()} hex.docs fetch #{lib})) end)

    Enum.each(stream, fn resp -> IO.inspect(resp) end)
  end

end

LocalHexdocs.fetch_all()


# libraries
# |> Task.async_stream(fn lib -> IO.puts(~c(mix hex.docs fetch #{lib})) end)

# |> Task.async_stream(fn lib -> System.shell("mix hex.docs fetch #{lib}", into: IO.stream()) end)
# |> Task.async_stream(fn lib -> System.cmd("mix", ["hex.docs", "fetch", lib]) end)

