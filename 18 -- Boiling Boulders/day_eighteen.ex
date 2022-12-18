defmodule DayEighteen do
  def run(file_path \\ "test_input") do
    cubes =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_line/1)
      |> MapSet.new()

    p1 = cubes |> surface_area()

    air_points =
      cubes
      |> Enum.reduce(MapSet.new(), fn pt, acc -> get_air_set(cubes, pt) |> MapSet.union(acc) end)
      |> Enum.filter(fn pt -> inside?(cubes, pt) end)
      |> IO.inspect()
      |> Enum.count()

    [part_one: p1, part_two: p1 - air_points * 6]
  end

  def inside?(cubes, {air_x, air_y, air_z}) do
    x = Enum.map(cubes, fn {x, _, _} -> x end)
    y = Enum.map(cubes, fn {_, y, _} -> y end)
    z = Enum.map(cubes, fn {_, _, z} -> z end)

    x_min = Enum.min(x)
    x_max = Enum.max(x)
    y_min = Enum.min(y)
    y_max = Enum.max(y)
    z_min = Enum.min(z)
    z_max = Enum.max(z)

    left = Enum.map(x_min..air_x, fn x -> {x, air_y, air_z} in cubes end)
    right = Enum.map(air_x..x_max, fn x -> {x, air_y, air_z} in cubes end)

    down = Enum.map(y_min..air_y, fn y -> {air_x, y, air_z} in cubes end)
    up = Enum.map(air_y..y_max, fn y -> {air_x, y, air_z} in cubes end)

    backward = Enum.map(air_z..z_max, fn z -> {air_x, air_y, z} in cubes end)
    forward = Enum.map(z_min..air_z, fn z -> {air_x, air_y, z} in cubes end)

    Enum.any?(left) and Enum.any?(right) and Enum.any?(up) and Enum.any?(down) and
      Enum.any?(forward) and Enum.any?(backward)
  end

  def surface_area(cubes) do
    Enum.reduce(cubes, 0, fn cube, acc -> acc + count_exposed(cubes, cube) end)
  end

  def get_air_set(cubes, {x, y, z}) do
    air_points =
      [
        {x, y + 1, z},
        {x, y - 1, z},
        {x - 1, y, z},
        {x + 1, y, z},
        {x, y, z + 1},
        {x, y, z - 1}
      ]
      |> MapSet.new()
      |> MapSet.difference(cubes)
  end

  def count_exposed(cubes, {x, y, z}) do
    covered_sides =
      [
        {x, y + 1, z},
        {x, y - 1, z},
        {x - 1, y, z},
        {x + 1, y, z},
        {x, y, z + 1},
        {x, y, z - 1}
      ]
      |> MapSet.new()
      |> MapSet.intersection(cubes)
      |> Enum.count()

    6 - covered_sides
  end

  def parse_line(line) do
    line
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end
