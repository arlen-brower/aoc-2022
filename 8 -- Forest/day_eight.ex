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

    load_map(file_path)
    |> calc_scenic()
  end

  def read_lines([], _r, acc), do: acc

  def read_lines([line | rest], r, acc) do
    new_map = read_line(line, r, 0, acc)
    read_lines(rest, r + 1, new_map)
  end

  def read_line([], _r, _c, acc), do: acc

  def read_line([tree | forest], r, c, %{} = acc) do
    read_line(forest, r, c + 1, Map.put(acc, {r, c}, tree))
  end

  def load_map(file_path) do
    input =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.to_charlist/1)

    read_lines(input, 0, %{})
  end

  def debug_scenic(tree_map, y, x) do
    r = look_right(tree_map, y, x)
    l = look_left(tree_map, y, x)
    u = look_up(tree_map, y, x)
    d = look_down(tree_map, y, x)
    [height: tree_map[{y, x}] - 48, right: r, left: l, up: u, down: d, score: r * l * u * d]
  end

  def calc_scenic(tree_map) do
    tree_map
    |> Enum.map(fn {{y, x}, _value} ->
      look_right(tree_map, y, x) *
        look_left(tree_map, y, x) *
        look_up(tree_map, y, x) *
        look_down(tree_map, y, x)
    end)
  end

  def look_right(tree_map, y, x) do
    trees = for i <- (x + 1)..(@cols - 1), tree_map[{y, i}] >= tree_map[{y, x}], do: i

    trees
    |> Enum.map(fn tree -> abs(x - tree) end)
    |> Enum.min(fn -> @cols - 1 - x end)
  end

  def look_left(tree_map, y, x) do
    trees = for i <- (x - 1)..0//-1, tree_map[{y, i}] >= tree_map[{y, x}], do: i

    trees
    |> Enum.map(fn tree -> abs(x - tree) end)
    |> Enum.min(fn -> x end)
  end

  def look_up(tree_map, y, x) do
    trees = for i <- (y - 1)..0//-1, tree_map[{i, x}] >= tree_map[{y, x}], do: i

    trees
    |> Enum.map(fn tree -> abs(y - tree) end)
    |> Enum.min(fn -> y end)
  end

  def look_down(tree_map, y, x) do
    trees = for i <- (y + 1)..(@rows - 1), tree_map[{i, x}] >= tree_map[{y, x}], do: i

    trees
    |> Enum.map(fn tree -> abs(y - tree) end)
    |> Enum.min(fn -> @rows - 1 - y end)
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
