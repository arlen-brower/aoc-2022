defmodule PartOne do
  defstruct AX: 4, # Rock, Rock
            AY: 8, # Rock, Paper
            AZ: 3, # Rock, Scissors
            BX: 1, # Paper, Rock
            BY: 5, # Paper, Paper
            BZ: 9, # Paper, Scissors
            CX: 7, # Scissors, Rock
            CY: 2, # Scissors, Paper
            CZ: 6  # Scissors, Scissors
end
#------------------------------------------------
defmodule PartTwo do
  defstruct AX: 3, # Lose against Rock
            AY: 4, # Draw against Rock
            AZ: 8, # Win against Rock
            BX: 1, # Lose against Paper
            BY: 5, # Draw against Paper
            BZ: 9, # Win against Paper
            CX: 2, # Lose against Scissors
            CY: 6, # Draw against Scissors
            CZ: 7  # Win against Scissors
end
#------------------------------------------------
defmodule DayTwo do
  def total_score(file_path, %PartOne{} = score_map), do: get_total(file_path, score_map)
  def total_score(file_path, %PartTwo{} = score_map), do: get_total(file_path, score_map)

  defp get_total(file_path, score_map) do
    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.map(fn x -> String.split(x) |> Enum.join() |> String.to_atom() end)
    |> Enum.reduce(0, fn x, acc -> Map.get(score_map, x) + acc end)
  end
end
