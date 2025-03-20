defmodule LocalHexdocs.Helpers do
  def running_tests? do
    "local_hexdocs/tests" == File.cwd!() |> path_end()
  end

  def hexpm_dir do
    if running_tests?() do
      "./.hex/docs/hexpm/" |> Path.expand()
    else
      # script is executing normally
      "~/.hex/docs/hexpm/" |> Path.expand()
    end
  end

  def path_end(string_path) when is_binary(string_path) do
    list = string_path |> String.split("/")
    {last, rest} = list |> List.pop_at(-1)
    {prev, _rest2} = rest |> List.pop_at(-1)
    "#{prev}/#{last}"
  end
end
