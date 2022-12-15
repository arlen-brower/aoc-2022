defmodule DayFifteen do
  @low 0
  @high 4_000_000

  def run(file_path \\ "test_input") do
    grid =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reduce(%{beacons: %{}, sensors: %{}}, fn line, grid_map ->
        parse_line(line, grid_map)
      end)

    p1 = nil
    # Part One
    # {min_x, max_x} = get_x_range(grid.beacons)
    # max_dist = get_max_distance(grid.sensors)
    # range = (min_x - max_dist - 1)..(max_x + max_dist + 1)
    # p1 = check_row(grid, 2_000_000, range)

    p2 = new_calc(grid)
    [part_one: p1, part_two: p2]
  end

  # ===================================================================================
  # The newer way I decided to narrow down candidates

  def new_calc(grid) do
    lines =
      grid.sensors
      |> Enum.map(&new_sensor_to_lines/1)
      |> List.flatten()

    [false: {x, y}] =
      lines
      |> Enum.reduce([], fn outer_line, intersects ->
        ints =
          Enum.reduce(lines, [], fn inner_line, acc ->
            [
              line_intersection(outer_line, inner_line)
              | acc
            ]
          end)

        ints ++ intersects
      end)
      |> Enum.reject(&(&1 == nil))
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_, f} -> f end, :desc)
      |> Enum.take(12)
      |> Enum.map(fn {point, _} -> {check_point?(grid.sensors, point), point} end)
      |> Enum.reject(fn {found, _} -> found end)

    x * 4_000_000 + y
  end

  def new_sensor_to_lines({{x, y}, dist}) do
    u = %{x: x, y: y - dist - 1}
    d = %{x: x, y: y + dist + 1}
    l = %{x: x - dist - 1, y: y}
    r = %{x: x + dist + 1, y: y}

    [
      %{p1: u, p2: r},
      %{p1: r, p2: d},
      %{p1: d, p2: l},
      %{p1: l, p2: u}
    ]
  end

  def det({a1, a2}, {b1, b2}), do: a1 * b2 - a2 * b1

  def det(%{x: a1, y: a2}, %{x: b1, y: b2}), do: a1 * b2 - a2 * b1

  def line_intersection(same_line, same_line), do: nil

  def line_intersection(line1, line2) do
    xdiff = {line1.p1.x - line1.p2.x, line2.p1.x - line2.p2.x}
    ydiff = {line1.p1.y - line1.p2.y, line2.p1.y - line2.p2.y}
    div = det(xdiff, ydiff)

    unless div == 0 do
      d = {det(line1.p1, line1.p2), det(line2.p1, line2.p2)}
      x = det(d, xdiff) |> div(div)
      y = det(d, ydiff) |> div(div)
      {x, y}
    end
  end

  # =====================================================================================
  # Old Part Two

  def old_part_two(grid) do
    sensors = grid.sensors

    lines = Enum.map(sensors, &sensor_to_lines/1)

    union = Enum.reduce(lines, MapSet.new(), fn x, acc -> MapSet.union(x, acc) end)

    {{x, y}, _} =
      lines
      |> Enum.reduce([], fn x, acc ->
        MapSet.intersection(union, x) |> MapSet.to_list() |> Kernel.++(acc)
      end)
      |> Enum.frequencies()
      |> Enum.max_by(fn {_, val} -> val end)

    x * @high + y
  end

  # =====================================================================================
  # Stuff for Part One and Parsing

  def sensor_to_lines({{x, y}, dist}) do
    u = {x, y - dist - 1}
    d = {x, y + dist + 1}

    pos_slope = 1
    neg_slope = -1

    MapSet.new()
    |> draw_lines(u, pos_slope, pos_slope, dist)
    |> draw_lines(u, neg_slope, pos_slope, dist)
    |> draw_lines(d, pos_slope, neg_slope, dist)
    |> draw_lines(d, neg_slope, neg_slope, dist)
    |> MapSet.reject(fn {x, y} -> x < @low or x > @high or y < @low or y > @high end)
  end

  def draw_lines(line_map, {x, y}, x_slope, y_slope, dist),
    do:
      Enum.reduce(0..dist, line_map, fn n, acc ->
        MapSet.put(acc, {x + x_slope * n, y + y_slope * n})
      end)

  def check_row(grid_map, y, range) do
    beacons = grid_map.beacons
    sensors = grid_map.sensors

    num_beacons = Enum.count(beacons, fn {{_, by}, _} -> by == y end)

    Enum.reduce(range, 0, fn x, acc ->
      cond do
        !Map.has_key?(sensors, {x, y}) and
            check_point?(sensors, {x, y}) ->
          acc + 1

        Map.has_key?(sensors, {x, y}) ->
          acc

        true ->
          acc
      end
    end)
    |> Kernel.-(num_beacons)
  end

  def check_point?(sensors, point) do
    Enum.map(sensors, fn {{x, y}, dist} -> in_range?(point, {x, y}, dist) end)
    |> Enum.any?()
  end

  def in_range?(point, sensor, distance) do
    cur_dist = distance(point, sensor)
    distance >= cur_dist and cur_dist != 0
  end

  def distance({x1, y1}, {x2, y2}), do: abs(x1 - x2) + abs(y1 - y2)

  def get_max_distance(sensors) do
    {_, dist} = Enum.max_by(sensors, fn {_, dist} -> dist end)
    dist
  end

  def get_x_range(beacons) do
    x_vals = Enum.map(beacons, fn {{x, _}, _} -> x end)

    {Enum.min(x_vals), Enum.max(x_vals)}
  end

  def parse_line(line, grid_map) do
    [x_sen, y_sen, x_bea, y_bea] =
      Regex.scan(~r/(-?\d+)/, line, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)

    new_sensors =
      Map.put(grid_map.sensors, {x_sen, y_sen}, abs(x_sen - x_bea) + abs(y_sen - y_bea))

    # Let's keep track of nearby sensors, just in case
    current_detected = Map.get(grid_map.beacons, {x_bea, y_bea}, 0)
    new_beacons = Map.put(grid_map.beacons, {x_bea, y_bea}, current_detected + 1)

    Map.put(grid_map, :beacons, new_beacons)
    |> Map.put(:sensors, new_sensors)
  end
end
