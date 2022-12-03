defmodule DayThree do
  # Part One
  def part_one(file_path) do
    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.map(&split_sack/1)
    |> Enum.sum()
  end

  def split_sack(sack) do
    {first, second} =
      sack
      |> String.split_at(div(String.length(sack), 2))

    letter =
      for n <- first |> String.graphemes(),
          String.contains?(second, n),
          do: n

    convert_item(letter)
  end

  # Part Two
  def part_two(file_path) do
    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.chunk_every(3)
    |> Enum.map(&get_badge/1)
    |> Enum.sum()
  end

  defp get_badge(group) do
    badge =
      for n <- group |> hd() |> String.graphemes(),
          String.contains?(Enum.fetch!(group, 1), n),
          String.contains?(Enum.fetch!(group, 2), n),
          do: n

    convert_item(badge)
  end

  defp convert_item(letter) do
    hd(letter)
    |> String.to_charlist()
    |> hd
    |> to_priority()
  end

  defp to_priority(num) when num > 96, do: num - 96
  defp to_priority(num), do: num - 38
end
