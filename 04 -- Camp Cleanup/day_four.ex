defmodule DayFour do
  def any_subset?([set1, set2]), do: MapSet.subset?(set1, set2) or MapSet.subset?(set2, set1)

  def part_one(file_path) do
    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_assignments/1)
    |> Enum.map(&any_subset?/1)
    # Basically -- count if true. Is there a nicer way?
    |> Enum.count(& &1)
  end

  def part_two(file_path) do
    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_assignments/1)
    |> Enum.map(fn [set1, set2] -> !MapSet.disjoint?(set1, set2) end)
    # Basically -- count if true. Is there a nicer way?
    |> Enum.count(& &1)
  end

  def parse_assignments(line) do
    line
    |> String.split(",")
    |> Enum.map(fn x ->
      x
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)
    end)
    |> Enum.map(&list_to_set/1)
  end

  def list_to_set([start, stop]) do
    MapSet.new(start..stop)
  end
end
