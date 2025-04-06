defmodule Mix.Tasks.LocalDocs do
  use Mix.Task

  def run(args) do
    case args do
      ["get"] ->
        LocalHexdocs.fetch_all()

      ["get_then_clean"] ->
        LocalHexdocs.fetch_all()
        LocalHexdocs.remove_stale_versions()

      ["list"] ->
        LocalHexdocs.display_downloaded_packages()

      ["versions"] ->
        LocalHexdocs.display_downloaded_packages_with_versions()

      ["multiple_versions"] ->
        LocalHexdocs.display_downloaded_packages_with_multiple_versions()

      ["to_clean"] ->
        LocalHexdocs.display_package_versions_to_remove()

      ["clean"] ->
        LocalHexdocs.remove_stale_versions()

      _ ->
        IO.puts("""
        I am unable to determine what you want to do.
        To download Hexdocs documentation, run 'mix local_docs get'
        To list all packages with downloaded Hexdocs, run 'mix local_docs list'

        To list all packages, each with a list of all downloaded Hexdocs versions, run 'mix local_docs versions'

        To list all packages with multiple downloaded Hexdocs versions, run 'mix local_docs multiple_versions'
        """)
    end
  end
end
