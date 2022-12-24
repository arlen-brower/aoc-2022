defmodule Day24 do
  def move_blizzards(basin) do
    Enum.reduce(basin, %{}, fn {{r, c}, blizz_list}, acc ->
      Enum.reduce(blizz_list, acc, fn
        "<", b ->
          add_blizzard({r, c - 1}, b, "<", basin)

        "^", b ->
          add_blizzard({r - 1, c}, b, "^", basin)

        ">", b ->
          add_blizzard({r, c + 1}, b, ">", basin)

        "v", b ->
          add_blizzard({r + 1, c}, b, "v", basin)

        "#", b ->
          Map.put(b, {r, c}, ["#"])
      end)
    end)
  end

  def add_blizzard(pos, basin, type, basin_walls) do
    IO.inspect(basin[pos])
    new_pos = if basin_walls[pos] == ["#"], do: wrap_around(basin_walls, pos, type), else: pos
    other_blizz = basin[new_pos]
    other_blizz = if other_blizz == nil, do: [], else: other_blizz
    Map.put(basin, new_pos, [type | other_blizz])
  end

  def wrap_around(basin, {r, c} = pos, type) do
    axis_filter =
      if type == "<" or type == ">" do
        Map.filter(basin, fn {{br, _c}, _} -> r == br end)
      else
        Map.filter(basin, fn {{_r, bc}, _} -> c == bc end)
      end

    wrapped_pos =
      cond do
        type == "<" ->
          {{_r, nc}, _} = Enum.max_by(axis_filter, fn {{_r, bc}, _} -> bc end)
          {r, nc - 1}

        type == ">" ->
          {{_r, nc}, _} = Enum.min_by(axis_filter, fn {{_r, bc}, _} -> bc end)
          {r, nc + 1}

        type == "^" ->
          {{nr, _c}, _} = Enum.max_by(axis_filter, fn {{br, _c}, _} -> br end)
          {nr - 1, c}

        type == "v" ->
          {{nr, _c}, _} = Enum.min_by(axis_filter, fn {{br, _c}, _} -> br end)
          {nr + 1, c}
      end

    IO.inspect(wrapped_pos)
  end

  def valid_moves(basin, {r, c} = position) do
    candidates = [
      d = {r + 1, c},
      r = {r, c + 1},
      l = {r, c - 1},
      u = {r - 1, c},
      position
    ]

    Enum.reject(candidates, fn {pr, pc} = pos ->
      Map.has_key?(basin, pos) or pr <= 0
    end)
  end

  def read_file(file_path) do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> parse_basin()
  end

  def parse_basin(basin_lines) do
    {parsed_points, _} =
      Enum.reduce(basin_lines, {%{}, 1}, fn line, {points, row} ->
        new_points = parse_line(line, points, row)
        {new_points, row + 1}
      end)

    parsed_points
  end

  def parse_line(line, points, row) do
    {new_points, _} =
      Enum.reduce(String.graphemes(line), {points, 1}, fn tile, {pts, col} ->
        case tile do
          "." ->
            {pts, col + 1}

          "#" ->
            {Map.put(pts, {row, col}, ["#"]), col + 1}

          ">" ->
            {Map.put(pts, {row, col}, [">"]), col + 1}

          "<" ->
            {Map.put(pts, {row, col}, ["<"]), col + 1}

          "^" ->
            {Map.put(pts, {row, col}, ["^"]), col + 1}

          "v" ->
            {Map.put(pts, {row, col}, ["v"]), col + 1}
        end
      end)

    new_points
  end

  def draw(grid) do
    IO.puts("---------------------------------------")
    rows = Enum.map(grid, fn {{r, _c}, _} -> r end)
    cols = Enum.map(grid, fn {{_r, c}, _} -> c end)

    min_r = Enum.min(rows)
    max_r = Enum.max(rows)

    min_c = Enum.min(cols)
    max_c = Enum.max(cols)

    Enum.each(min_r..max_r, fn r ->
      Enum.each(min_c..max_c, fn c ->
        cond do
          Map.has_key?(grid, {r, c}) and length(grid[{r, c}]) > 1 ->
            IO.write(length(grid[{r, c}]))

          Map.has_key?(grid, {r, c}) ->
            IO.write(hd(grid[{r, c}]))

          true ->
            IO.write(" ")
        end
      end)

      IO.write("\n")
    end)
  end
end
