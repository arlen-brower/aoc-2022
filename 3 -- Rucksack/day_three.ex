defmodule DayThree do
  def rucksack(file_path) do
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

    num =
      hd(letter)
      |> String.to_charlist()
      |> hd

    if num > 96 do
      num - 96
    else
      num - 38
    end
  end
end
