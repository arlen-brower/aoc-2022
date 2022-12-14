defmodule DayFourteen do
  @sand_origin {500, 0}
  @void_limit 170

  @type point() :: tuple()
  @type line() :: %{p1: point(), p2: point()}

  def run(file_path \\ "test_input") do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_lines/1)
    |> List.flatten()
    |> Enum.reduce(%{}, fn line, acc -> draw_lines(acc, line) end)
    |> simulate_sand()
  end

  def simulate_sand(lines_list, sand_map \\ %{}, rounds \\ 0) do
    IO.inspect(rounds)

    unless rounds > map_size(sand_map) do
      new_sand = step(lines_list, sand_map, @sand_origin)

      simulate_sand(lines_list, new_sand, rounds + 1)
    else
      rounds - 1
    end
  end

  def step(lines_list, sand_map, {px, py} = point) do
    down = {px, py + 1}
    left = {px - 1, py + 1}
    right = {px + 1, py + 1}

    cond do
      not is_stopped?(lines_list, sand_map, down) ->
        step(lines_list, sand_map, down)

      not is_stopped?(lines_list, sand_map, left) ->
        step(lines_list, sand_map, left)

      not is_stopped?(lines_list, sand_map, right) ->
        step(lines_list, sand_map, right)

      true ->
        # [point | sand_map]
        Map.put(sand_map, point, point)
    end
  end

  # For part two only
  def is_stopped?(lines_list, sand_map, {px, py}) when py >= @void_limit, do: true

  def is_stopped?(lines_list, sand_map, point) do
    if Map.has_key?(sand_map, point) do
      true
    else
      Map.has_key?(lines_list, point)
    end
  end

  def draw_lines(line_map, %{p1: {x1, y}, p2: {x2, y}}),
    do: Enum.reduce(x1..x2, line_map, fn x, acc -> Map.put(acc, {x, y}, {x, y}) end)

  def draw_lines(line_map, %{p1: {x, y1}, p2: {x, y2}}),
    do: Enum.reduce(y1..y2, line_map, fn y, acc -> Map.put(acc, {x, y}, {x, y}) end)

  def parse_lines(line_string) do
    line_string
    |> String.split(" -> ")
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [p1, p2] -> parse_line(p1, p2) end)
  end

  def parse_line(point_one, point_two) do
    %{p1: parse_point(point_one), p2: parse_point(point_two)}
  end

  def parse_point(point) do
    [x, y] = String.split(point, ",")
    send(self(), y)
    {String.to_integer(x), String.to_integer(y)}
  end
end
