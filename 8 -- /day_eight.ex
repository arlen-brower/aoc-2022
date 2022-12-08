defmodule DayEight do
  @rows 99
  @cols 99

  def run(file_path \\ "test_input") do
    input =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)

    horizontal =
      input
      |> Enum.map(&String.to_charlist/1)
      |> Enum.with_index()

    vertical =
      input
      |> Enum.map(&String.graphemes/1)
      |> Enum.zip()
      |> Enum.map(fn x -> x |> Tuple.to_list() |> Enum.join() end)
      |> Enum.map(&String.to_charlist/1)
      |> Enum.with_index()

    %{}
    |> rows(horizontal)
    |> cols(vertical)
  end

  def cols(vis_map, tree_rows) do
    row_list =
      tree_rows
      |> List.foldl(vis_map, fn {trees, idx}, acc_map -> col_look(acc_map, trees, idx) end)
  end

  def col_look(vis_map, tree_row, col_num) do
    {_, l_ids, _} = tree_row |> List.foldl({0, [], 0}, &fold_helper/2)

    r_ids =
      tree_row
      |> List.foldr({0, [], 0}, &fold_helper/2)
      |> elem(1)
      |> Enum.map(fn x -> @cols - 1 - x end)

    for x <- l_ids ++ r_ids, into: vis_map, do: {{x, col_num}, "t"}
  end

  def rows(vis_map, tree_rows) do
    row_list =
      tree_rows
      |> List.foldl(vis_map, fn {trees, idx}, acc_map -> row_look(acc_map, trees, idx) end)
  end

  def row_look(vis_map, tree_row, row_num) do
    {_, l_ids, _} = tree_row |> List.foldl({0, [], 0}, &fold_helper/2)

    r_ids =
      tree_row
      |> List.foldr({0, [], 0}, &fold_helper/2)
      |> elem(1)
      |> Enum.map(fn x -> @rows - 1 - x end)

    for x <- l_ids ++ r_ids, into: vis_map, do: {{row_num, x}, "t"}
  end

  def fold_helper(x, {max, vis, idx}) do
    if x > max do
      {x, [idx | vis], idx + 1}
    else
      {max, vis, idx + 1}
    end
  end
end
