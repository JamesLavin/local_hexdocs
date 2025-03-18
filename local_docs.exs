Code.require_file("./local_hexdocs.ex")
Code.ensure_loaded(LocalHexdocs)

{_parsed_switches_kw_list, args_list, _invalid_opts} =
  System.argv()
  |> OptionParser.parse(strict: [])

cond do
  "get" in args_list ->
    LocalHexdocs.fetch_all()

  "list" in args_list ->
    LocalHexdocs.downloaded_packages()

  "versions" in args_list ->
    LocalHexdocs.downloaded_packages_with_versions()

  "multiple_versions" in args_list ->
    LocalHexdocs.downloaded_packages_with_multiple_versions()

  true ->
    IO.puts("I am unable to determine what you want to do.\n")
    IO.puts("To download Hexdocs documentation, run 'elixir local_docs.exs get'\n")
    IO.puts("To list all packages with downloaded Hexdocs, run 'elixir local_docs.exs list'")
    IO.puts("To list all packages, each with a list of all downloaded Hexdocs versions, run 'elixir local_docs.exs versions'")
    IO.puts("To list all packages with multiple downloaded Hexdocs versions, run 'elixir local_docs.exs multiple_versions'")
end
