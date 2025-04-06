defmodule LocalHexdocs.Helpers do
  def running_tests? do
    mix_env() == :test
  end

  def mix_env do
    Mix.env()
  end

  def cwd do
    File.cwd()
  end

  def top_dir do
    if running_tests?() do
      "./test/" |> Path.expand()
    else
      # script is executing normally
      "./" |> Path.expand()
    end
  end

  def hexpm_dir do
    if running_tests?() do
      "./test/.hex/docs/hexpm/" |> Path.expand()
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
