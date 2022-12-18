defmodule DayEighteen do
  def run(file_path \\ "test_input") do
    cubes =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_line/1)
      |> MapSet.new()

    p1 = cubes |> surface_area()

    {solid_cube, x_bounds, y_bounds, z_bounds, start_point} = find_box(cubes)
    node_map = points_to_nodes(solid_cube)
    filter_fun = &(not MapSet.member?(cubes, &1) and in_bounds(&1, x_bounds, y_bounds, z_bounds))

    p2 =
      start_bfs(node_map, start_point, filter_fun)
      |> Enum.reject(fn {_, node} -> node.visited end)
      |> nodes_to_points()
      |> surface_area()

    [part_one: p1, part_two: p2]
  end

  def in_bounds({x, y, z}, xbounds, ybounds, zbounds) do
    x in xbounds and y in ybounds and z in zbounds
  end

  def surface_area(cubes) do
    Enum.reduce(cubes, 0, fn cube, acc -> acc + count_exposed(cubes, cube) end)
  end

  def find_box(cubes) do
    x = Enum.map(cubes, fn {x, _, _} -> x end)
    y = Enum.map(cubes, fn {_, y, _} -> y end)
    z = Enum.map(cubes, fn {_, _, z} -> z end)

    x_min = Enum.min(x)
    x_max = Enum.max(x)

    y_min = Enum.min(y)
    y_max = Enum.max(y)

    z_min = Enum.min(z)
    z_max = Enum.max(z)

    cube_list =
      for x <- x_min..x_max, do: for(y <- y_min..y_max, do: for(z <- z_min..z_max, do: {x, y, z}))

    cube_map =
      cube_list
      |> List.flatten()
      |> MapSet.new()

    {cube_map, x_min..x_max, y_min..y_max, z_min..z_max, {x_min, y_min, z_min}}
  end

  def points_to_nodes(cubes) do
    Enum.reduce(cubes, %{}, fn label, acc ->
      Map.put(acc, label, %{visited: false, distance: :inf, label: label})
    end)
  end

  def nodes_to_points(nodes) do
    Enum.reduce(nodes, MapSet.new(), fn {label, _}, acc -> MapSet.put(acc, label) end)
  end

  def start_bfs(nodes, start, filter_fun) do
    nodes[start]
    |> Map.put(:visited, true)
    |> Map.put(:distance, 0)
    |> update_nodes(start, nodes)
    |> bfs([start], filter_fun)
  end

  def bfs(nodes, [], _), do: nodes

  def bfs(nodes, q, filter_fun) do
    s = q_front(q)
    q = q_pop(q)

    {new_nodes, new_q} =
      Enum.reduce(filter_neighbours(nodes[s], filter_fun), {nodes, q}, fn u, {v_acc, q_acc} ->
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

    bfs(new_nodes, new_q, filter_fun)
  end

  def q_front(queue), do: List.first(queue)
  def q_push(queue, label), do: queue ++ [label]

  def q_pop(queue) do
    {_, new_q} = List.pop_at(queue, 0)
    new_q
  end

  def update_nodes(node, label, nodes) do
    Map.put(nodes, label, node)
  end

  def reset_visited(nodes, ignore \\ []) do
    Enum.reduce(nodes, nodes, fn {label, node}, acc ->
      if label in ignore do
        acc
      else
        update_nodes(%{node | visited: false}, label, acc)
      end
    end)
  end

  def filter_neighbours(%{label: {x, y, z}}, filter_fun) do
    [
      {x, y + 1, z},
      {x, y - 1, z},
      {x - 1, y, z},
      {x + 1, y, z},
      {x, y, z + 1},
      {x, y, z - 1}
    ]
    |> Enum.filter(filter_fun)
  end

  def neighbours({x, y, z}) do
    [
      {x, y + 1, z},
      {x, y - 1, z},
      {x - 1, y, z},
      {x + 1, y, z},
      {x, y, z + 1},
      {x, y, z - 1}
    ]
  end

  def count_exposed(cubes, {x, y, z}) do
    covered_sides =
      neighbours({x, y, z})
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
