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

    # Part One
    # {min_x, max_x} = get_x_range(grid.beacons)
    # max_dist = get_max_distance(grid.sensors)
    # range = (min_x - max_dist - 1)..(max_x + max_dist + 1)
    # check_row(grid, 2_000_000, range)

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
          IO.inspect({x, y})
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
