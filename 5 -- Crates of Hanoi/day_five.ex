defmodule DayFive do
  @crate_format ~r/\s?(\s|\[)(.|\s)(\s|\])\s?/
  @num_stacks 9

  def part_one(file_path) do
    [stacks, moves] =
      file_path
      |> File.read!()
      |> String.trim_trailing()
      |> String.split(~r/\n 1 .*\n\n/)
  end

  def parse_stacks(stacks) do
    stacks
    |> String.split("\n")
    |> Enum.map(fn row -> String.replace(row, @crate_format, "\\2") end)
  end
end
