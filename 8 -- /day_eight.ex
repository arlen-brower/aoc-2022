defmodule DayEight do
  @columns 5
  @rows 5

  @type trees :: tuple()

  def run(file_path \\ "test_input") do
    trees =
      file_path
      |> File.read!()
      |> String.replace("\n", "")
      |> String.to_charlist()
      |> List.to_tuple()

    iter_rows(%{}, trees, 0, @rows)
  end

  def iter_rows(vis_map, _trees, stop, stop), do: vis_map

  def iter_rows(vis_map, trees, row, stop) do
    iter_cols(vis_map, trees, row, 0, @columns)
    |> iter_rows(trees, row + 1, stop)
  end

  def iter_cols(vis_map, _trees, _row, stop, stop), do: vis_map

  def iter_cols(vis_map, trees, row, col, stop) do
    IO.inspect({col, row})
    get(trees, col, row) |> IO.inspect()
    iter_cols(vis_map, trees, row, col + 1, stop)
  end

  @spec get(trees(), integer(), integer()) :: integer()
  def get(trees, x, y), do: elem(trees, y * @columns + x)
end
