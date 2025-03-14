Code.require_file("./local_hexdocs.ex")
Code.ensure_loaded(LocalHexdocs)

LocalHexdocs.fetch_all()


# libraries
# |> Task.async_stream(fn lib -> IO.puts(~c(mix hex.docs fetch #{lib})) end)

# |> Task.async_stream(fn lib -> System.shell("mix hex.docs fetch #{lib}", into: IO.stream()) end)
# |> Task.async_stream(fn lib -> System.cmd("mix", ["hex.docs", "fetch", lib]) end)

