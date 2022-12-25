defmodule Day24 do
  @start {1, 2, 0}
  @part_twoa {37, 101, 232}
  @two_b {1, 2, 487}

  def run(file_path \\ "test_input") do
    basin =
      file_path
      |> read_file()

    all = all_blizzards(basin, 1000)
    points = get_clear_points(all)
    distances = start_bfs(points, @two_b)
    {{max_r, _}, _} = Enum.max_by(basin, fn {{r, _c}, _} -> r end)
    {{_, max_c}, _} = Enum.max_by(basin, fn {{_r, c}, _} -> c end)

    goal = {max_r, max_c - 1}

    extract_goal(distances, goal)
    # extract_goal(distances, {1, 2})
  end

  def extract_goal(distances, {goal_r, goal_c}) do
    {_, %{distance: dist}} =
      distances
      |> Map.filter(fn {{r, c, _}, _} -> r == goal_r and c == goal_c end)
      |> Enum.min_by(fn {{_r, _c, _}, %{distance: dist}} -> dist end)

    dist
  end

  def valid_moves(points, {r, c, t}) do
    candidates = [
      {r, c + 1, t + 1},
      {r + 1, c, t + 1},
      {r, c, t + 1},
      {r - 1, c, t + 1},
      {r, c - 1, t + 1}
    ]

    Enum.filter(candidates, fn pos ->
      Map.has_key?(points, pos)
    end)
  end

  def start_bfs(points, start) do
    points[start]
    |> Map.put(:visited, true)
    |> Map.put(:distance, 0)
    |> update_nodes(start, points)
    |> bfs([start])
  end

  def bfs(nodes, []), do: nodes

  def bfs(nodes, q) do
    s = q_front(q)
    q = q_pop(q)

    {new_nodes, new_q} =
      Enum.reduce(valid_moves(nodes, s), {nodes, q}, fn u, {v_acc, q_acc} ->
        unless v_acc[u].visited do
          updated_v =
            v_acc[u]
            |> Map.put(:visited, true)
            |> Map.put(:distance, v_acc[s].distance + 1)
            |> update_nodes(u, v_acc)

          {updated_v, q_push(q_acc, u)}
        else
          {v_acc, q_acc}
        end
      end)

    bfs(new_nodes, new_q)
  end

  def update_nodes(node, label, nodes) do
    Map.put(nodes, label, node)
  end

  def get_clear_points(all_blizz) do
    times = map_size(all_blizz)
    rows = Enum.map(all_blizz[1], fn {{r, _c}, _} -> r end)
    cols = Enum.map(all_blizz[1], fn {{_r, c}, _} -> c end)

    min_r = Enum.min(rows) + 1
    max_r = Enum.max(rows) - 1

    min_c = Enum.min(cols) + 1
    max_c = Enum.max(cols) - 1

    goal_r = max_r + 1
    goal_c = max_c

    Enum.reduce(0..(times - 1), Map.new(), fn t, tacc ->
      Enum.reduce(min_r..max_r, tacc, fn r, racc ->
        Enum.reduce(min_c..max_c, racc, fn c, cacc ->
          if Map.has_key?(all_blizz[t], {r, c}) do
            cacc
          else
            Map.put(cacc, {r, c, t}, %{visited: false, distance: :inf})
          end
          |> Map.put({1, 2, t}, %{visited: false, distance: :inf})
          |> Map.put({goal_r, goal_c, t}, %{visited: false, distance: :inf})
        end)
      end)
    end)
  end

  def all_blizzards(initial, rounds) do
    {all, _} =
      Enum.reduce(1..rounds, {%{0 => initial}, initial}, fn i, {acc, last_basin} ->
        next = move_blizzards(last_basin)
        {Map.put(acc, i, next), next}
      end)

    all
  end

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
    new_pos = if basin_walls[pos] == ["#"], do: wrap_around(basin_walls, pos, type), else: pos
    other_blizz = basin[new_pos]
    other_blizz = if other_blizz == nil, do: [], else: other_blizz
    Map.put(basin, new_pos, [type | other_blizz])
  end

  def wrap_around(basin, {r, c}, type) do
    axis_filter =
      if type == "<" or type == ">" do
        Map.filter(basin, fn {{br, _c}, _} -> r == br end)
      else
        Map.filter(basin, fn {{_r, bc}, _} -> c == bc end)
      end

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

  def draw(grid, pos \\ nil) do
    IO.puts("---------------------------------------")
    rows = Enum.map(grid, fn {{r, _c}, _} -> r end)
    cols = Enum.map(grid, fn {{_r, c}, _} -> c end)

    min_r = Enum.min(rows)
    max_r = Enum.max(rows)

    min_c = Enum.min(cols)
    max_c = Enum.max(cols)

    grid = if pos, do: Map.put(grid, pos, ["E"]), else: grid

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

  def q_front(queue), do: List.first(queue)
  def q_push(queue, label), do: queue ++ [label]

  def q_pop(queue) do
    {_, new_q} = List.pop_at(queue, 0)
    new_q
  end
end
