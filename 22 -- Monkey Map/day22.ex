defmodule Day22 do
  @face_val %{"R" => 0, "D" => 1, "L" => 2, "U" => 3}

  @face1_row 1
  @face1_col 51
  @face2_row 1
  @face2_col 101
  @face3_row 51
  @face3_col 51
  @face4_row 101
  @face4_col 51
  @face5_row 101
  @face5_col 1
  @face6_row 151
  @face6_col 1

  def run(file_path \\ "test_input") do
    {raw_instructions, raw_board} =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> List.pop_at(-1)

    board = parse_board(raw_board)
    instructions = parse_instructions(raw_instructions)

    [{start_pos, _}] =
      board
      |> Enum.sort_by(fn {{_r, c}, _} -> c end, :asc)
      |> Enum.sort_by(fn {{r, _c}, _} -> r end, :asc)
      |> Enum.take(1)

    execute_instructions(board, instructions, start_pos, "R")
  end

  def which_face({p_row, p_col}) do
    cond do
      p_row >= 1 and p_row <= 50 and p_col >= 51 and p_col <= 100 -> :one
      p_row >= 1 and p_row <= 50 and p_col >= 101 and p_col <= 150 -> :two
      p_row >= 51 and p_row <= 100 and p_col >= 51 and p_col <= 100 -> :three
      p_row >= 101 and p_row <= 150 and p_col >= 51 and p_col <= 100 -> :four
      p_row >= 101 and p_row <= 150 and p_col >= 1 and p_col <= 50 -> :five
      p_row >= 151 and p_row <= 200 and p_col >= 1 and p_col <= 50 -> :six
    end
  end

  def cube_wrap_around(board, {row, col} = pos, direction) do
    cube = which_face({row, col})

    rel_row = rem(row - 1, 50)
    rel_col = rem(col - 1, 50)

    {new_pos, new_dir} =
      case {cube, direction} do
        # To Face 6
        {:one, "U"} -> {{rel_col + @face6_row, @face6_col}, "R"}
        # To Face 5 (INV)
        {:one, "L"} -> {{49 - rel_row + @face5_row, @face5_col}, "R"}
        # To Face 6 
        {:two, "U"} -> {{@face6_row + 49, rel_col + @face6_col}, "U"}
        # To Face 4 (INV)
        {:two, "R"} -> {{49 - rel_row + @face4_row, @face4_col + 49}, "L"}
        # To Face 3
        {:two, "D"} -> {{rel_col + @face3_row, @face3_col + 49}, "L"}
        # To Face 2
        {:three, "R"} -> {{@face2_row + 49, rel_row + @face2_col}, "U"}
        # To Face 5
        {:three, "L"} -> {{@face5_row, rel_row + @face5_col}, "D"}
        # To Face 2 (INV)
        {:four, "R"} -> {{49 - rel_row + @face2_row, @face2_col + 49}, "L"}
        # To Face 6
        {:four, "D"} -> {{rel_col + @face6_row, @face6_col + 49}, "L"}
        # To Face 3
        {:five, "U"} -> {{rel_col + @face3_row, @face3_col}, "R"}
        # To Face 1 (INV)
        {:five, "L"} -> {{49 - rel_row + @face1_row, @face1_col}, "R"}
        # To Face 1
        {:six, "L"} -> {{@face1_row, rel_row + @face1_col}, "D"}
        # To Face 4
        {:six, "R"} -> {{@face4_row + 49, rel_row + @face4_col}, "U"}
        # To Face 2
        {:six, "D"} -> {{@face2_row, rel_col + @face2_col}, "D"}
      end

    IO.inspect({new_pos, new_dir})

    if board[new_pos] == "." do
      {new_pos, new_dir}
    else
      {pos, direction}
    end
  end

  def execute_instructions(_board, [], {{r, c}, dir}, _facing),
    do: 1000 * r + 4 * c + @face_val[dir]

  def execute_instructions(board, [units | []], {r, c}, facing),
    do: execute_instructions(board, [], move_player(board, {r, c}, facing, units), facing)

  def execute_instructions(board, [units, change_dir | rest], player_pos, direction) do
    {new_pos, cube_dir} = move_player(board, player_pos, direction, units)
    new_dir = change_direction(change_dir, cube_dir)
    execute_instructions(board, rest, new_pos, new_dir)
  end

  def change_direction(change, current) do
    case {change, current} do
      {"L", "L"} -> "D"
      {"L", "D"} -> "R"
      {"L", "R"} -> "U"
      {"L", "U"} -> "L"
      {"R", "L"} -> "U"
      {"R", "D"} -> "L"
      {"R", "R"} -> "D"
      {"R", "U"} -> "R"
    end
  end

  def move_player(board, player_pos, direction, units) do
    Enum.reduce(1..units, {player_pos, direction}, fn _i, {{r, c}, dir} ->
      move_player(board, {r, c}, dir)
    end)
  end

  def move_player(board, {row, col}, direction) do
    new_pos =
      case direction do
        "D" -> {row + 1, col}
        "U" -> {row - 1, col}
        "L" -> {row, col - 1}
        "R" -> {row, col + 1}
      end

    cond do
      board[new_pos] == "#" ->
        {{row, col}, direction}

      board[new_pos] == "." ->
        {new_pos, direction}

      true ->
        cube_wrap_around(board, {row, col}, direction)
        |> IO.inspect()

        # true -> wrap_around(board, {row, col}, new_pos, direction)
    end
  end

  def wrap_around(board, old_pos, {row, col}, direction) do
    axis_filter =
      cond do
        direction == "L" or direction == "R" ->
          Map.filter(board, fn {{r, _c}, _} -> r == row end)

        direction == "U" or direction == "D" ->
          Map.filter(board, fn {{_r, c}, _} -> c == col end)
      end

    {new_pos, tile_type} =
      case direction do
        "U" ->
          Enum.max_by(axis_filter, fn {{r, _c}, _} -> r end)

        "D" ->
          Enum.min_by(axis_filter, fn {{r, _c}, _} -> r end)

        "L" ->
          Enum.max_by(axis_filter, fn {{_r, c}, _} -> c end)

        "R" ->
          Enum.min_by(axis_filter, fn {{_r, c}, _} -> c end)
      end

    if tile_type == "." do
      new_pos
    else
      old_pos
    end
  end

  def parse_instructions(raw) do
    units =
      Regex.scan(~r/(\d+)/, raw, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)

    dirs = Regex.scan(~r/(R|L)/, raw, capture: :all_but_first) |> List.flatten()

    Enum.zip(units, dirs)
    |> Enum.reduce([], fn {unit, dir}, acc -> acc ++ [unit, dir] end)
    |> Kernel.++([List.last(units)])
  end

  def parse_board(board) do
    {parsed_board, _} =
      Enum.reduce(board, {%{}, 1}, fn line, {board, row} ->
        new_board = parse_line(line, board, row)
        {new_board, row + 1}
      end)

    parsed_board
  end

  def parse_line(line, board, row) do
    {new_board, _} =
      Enum.reduce(String.graphemes(line), {board, 1}, fn tile, {board, col} ->
        case tile do
          " " ->
            {board, col + 1}

          "." ->
            {Map.put(board, {row, col}, "."), col + 1}

          "#" ->
            {Map.put(board, {row, col}, "#"), col + 1}
        end
      end)

    new_board
  end
end
