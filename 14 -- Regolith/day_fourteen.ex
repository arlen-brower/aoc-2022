defmodule DayFourteen do
  @origin_x 500
  @origin_y 0
  @sand_origin {@origin_x, @origin_y}

  @type path() :: String.t()
  @type point() :: tuple()
  @type raw_line() :: String.t()
  @type raw_point() :: String.t()
  @type line() :: %{p1: point(), p2: point()}
  @type sand_map() :: %{point() => point()}
  @type stone_map() :: %{point() => point()}
  @type rounds() :: integer()

  # =======================================================================
  # Run
  # =======================================================================
  @spec run(path()) :: rounds()
  def run(file_path \\ "test_input") do
    input =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_lines/1)
      |> List.flatten()

    floor_level = get_floor_value(input)

    input
    |> add_floor(floor_level)
    |> Enum.reduce(%{}, fn line, acc -> draw_lines(acc, line) end)
    |> simulate_sand()
  end

  # =======================================================================
  # Simulate
  # =======================================================================
  @spec simulate_sand(stone_map(), sand_map(), rounds()) :: rounds()
  def simulate_sand(stone_map, sand_map \\ %{}, rounds \\ 0)

  def simulate_sand(_stone_map, %{} = sand_map, rounds) when rounds > map_size(sand_map),
    do: rounds - 1

  def simulate_sand(stone_map, sand_map, rounds) do
    new_sand = step(stone_map, sand_map, @sand_origin)
    simulate_sand(stone_map, new_sand, rounds + 1)
  end

  # =======================================================================
  # Step logic
  # =======================================================================
  @spec step(stone_map(), sand_map(), point()) :: sand_map()
  def step(stone_map, sand_map, {px, py} = point) do
    down = {px, py + 1}
    left = {px - 1, py + 1}
    right = {px + 1, py + 1}

    cond do
      # Is the space below free?
      not is_stopped?(stone_map, sand_map, down) ->
        step(stone_map, sand_map, down)

      # Else, is the space to the left free?
      not is_stopped?(stone_map, sand_map, left) ->
        step(stone_map, sand_map, left)

      # Else, is the space to the right free?
      not is_stopped?(stone_map, sand_map, right) ->
        step(stone_map, sand_map, right)

      # Nothing is free; come to a rest
      true ->
        Map.put(sand_map, point, point)
    end
  end

  @spec is_stopped?(stone_map(), sand_map(), point()) :: boolean()
  def is_stopped?(stone_map, sand_map, point) do
    if Map.has_key?(sand_map, point) do
      true
    else
      Map.has_key?(stone_map, point)
    end
  end

  # =======================================================================
  # Conversion of points to Map
  # =======================================================================
  @spec draw_lines(stone_map(), line()) :: stone_map()
  def draw_lines(line_map, %{p1: {x1, y}, p2: {x2, y}}),
    do: Enum.reduce(x1..x2, line_map, fn x, acc -> Map.put(acc, {x, y}, {x, y}) end)

  def draw_lines(line_map, %{p1: {x, y1}, p2: {x, y2}}),
    do: Enum.reduce(y1..y2, line_map, fn y, acc -> Map.put(acc, {x, y}, {x, y}) end)

  # =======================================================================
  # Floor logic
  # =======================================================================
  @spec add_floor(list(line()), integer()) :: list(line())
  def add_floor(lines, floor_level) do
    [
      %{
        p1: {@origin_x - floor_level * 2, floor_level},
        p2: {@origin_x + floor_level * 2, floor_level}
      }
      | lines
    ]
  end

  @spec get_floor_value(list(line())) :: integer()
  def get_floor_value(lines) do
    lines
    |> Enum.map(fn %{p1: {_, y1}, p2: {_, y2}} -> max(y1, y2) end)
    |> Enum.max()
    |> Kernel.+(2)
  end

  # =======================================================================
  # Parsing Logic
  # =======================================================================

  @spec parse_lines(raw_line()) :: line()
  def parse_lines(line_string) do
    line_string
    |> String.split(" -> ")
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [p1, p2] -> parse_line(p1, p2) end)
  end

  @spec parse_line(raw_point(), raw_point()) :: line()
  def parse_line(point_one, point_two) do
    %{p1: parse_point(point_one), p2: parse_point(point_two)}
  end

  @spec parse_point(raw_point()) :: point()
  def parse_point(point) do
    [x, y] = String.split(point, ",")
    send(self(), y)
    {String.to_integer(x), String.to_integer(y)}
  end
end
