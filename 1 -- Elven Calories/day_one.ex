defmodule DayOne do
  def most_calories(input_file, num \\ 1) do
    input_file
    |> File.read!()
    |> String.split("\n\n", trim: true)
    |> Enum.map(&parse_elf/1)
    |> Enum.sort(:desc)
    |> Enum.take(num)
    |> Enum.sum()
  end

  defp parse_elf(elf) do
    elf
    |> String.split("\n", trim: true)
    |> Enum.map(&String.to_integer/1)
    |> Enum.sum()
  end
end
