defmodule DayOne do
  def most_calories(input_file, num \\ 1) do
    {:ok, elves} = File.read(input_file)

    {top, _rest} =
      elves
      |> String.trim_trailing()
      |> String.split("\n\n")
      |> Enum.map(&parse_elf/1)
      |> Enum.sort(:desc)
      |> Enum.split(num)

    Enum.sum(top)
  end

  defp parse_elf(elf) do
    elf
    |> String.split("\n")
    |> Enum.map(&String.to_integer/1)
    |> Enum.sum()
  end
end
