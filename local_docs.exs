# Code.require_file("./lib/local_hexdocs.ex")
Code.ensure_all_loaded([LocalHexdocs.Helpers, LocalHexdocs])

{_parsed_switches_kw_list, args_list, _invalid_opts} =
  System.argv()
  |> OptionParser.parse(strict: [])

cond do
  "get" in args_list ->
    LocalHexdocs.fetch_all()

  "get_then_clean" in args_list ->
    LocalHexdocs.fetch_all()
    LocalHexdocs.remove_stale_versions()

  "list" in args_list ->
    LocalHexdocs.downloaded_packages()

  "versions" in args_list ->
    LocalHexdocs.display_downloaded_packages_with_versions()

  "multiple_versions" in args_list ->
    LocalHexdocs.display_downloaded_packages_with_multiple_versions()

  "to_clean" in args_list ->
    LocalHexdocs.display_package_versions_to_remove()

  "clean" in args_list ->
    LocalHexdocs.remove_stale_versions()

  true ->
    IO.puts("I am unable to determine what you want to do.\n")
    IO.puts("To download Hexdocs documentation, run 'mix run local_docs.exs get'\n")
    IO.puts("To list all packages with downloaded Hexdocs, run 'mix run local_docs.exs list'")

    IO.puts(
      "To list all packages, each with a list of all downloaded Hexdocs versions, run 'mix run local_docs.exs versions'"
    )

    IO.puts(
      "To list all packages with multiple downloaded Hexdocs versions, run 'mix run local_docs.exs multiple_versions'"
    )
end
