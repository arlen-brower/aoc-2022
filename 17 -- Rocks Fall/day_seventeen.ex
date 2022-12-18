defmodule DaySeventeen do
  # Plug your input into here:
  @jet_sample ">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>"
  @jet_size String.length(@jet_sample)
  @floor_set MapSet.new(for x <- 0..6, do: {x, 0})
  @rounds 1_000_000_000_000

  # I chose to limit how many times it runs to 4,000.
  # This may need to be adjusted for larger sequences.
  @max_runs 4_000

  @type shape_step() :: integer()
  @type jet_step() :: integer()
  @type height() :: integer()
  @type point() :: tuple()
  @type direction() :: String.t()
  @type rock() :: MapSet.t(point())
  @type all_rocks() :: MapSet.t(point())
  @type height_map() :: %{point() => height()}

  @spec run() :: [part_one: height(), part_two: height()]
  def run() do
    y_map = rock_round(@floor_set, 0, 0, 0, %{})
    len = map_size(y_map)

    diffs =
      Enum.reduce(2..len, "", fn shape, acc ->
        acc <> ((y_map[shape] - y_map[shape - 1]) |> Integer.to_string())
      end)

    {:ok, cycle} =
      Regex.scan(~r/(.+?)\1+/, diffs, capture: :all_but_first)
      |> List.flatten()
      |> Enum.sort_by(&String.length/1, :desc)
      |> hd()
      |> Regex.compile()

    [{offset, cycle_rocks}] = Regex.run(cycle, diffs, return: :index)
    offset = offset + 1
    offset_height = y_map[offset]
    cycle_height = y_map[cycle_rocks + offset] - offset_height
    possible_cycles = (@rounds - offset) / cycle_rocks
    incomplete_cycle = possible_cycles - trunc(possible_cycles)
    num_incomplete = (incomplete_cycle * cycle_rocks) |> round()
    remaining_height = y_map[num_incomplete + offset]
    total = trunc(possible_cycles) * cycle_height + remaining_height

    [part_one: y_map[2022], part_two: total]
  end

  @spec rock_round(all_rocks(), height(), shape_step(), jet_step(), height_map()) :: height_map()
  def rock_round(_rock_set, _y, shape, _jet, y_map) when shape == @max_runs,
    do: y_map

  def rock_round(rock_set, y, shape_idx, step, y_map) do
    if rem(shape_idx, 1000) == 0 do
      IO.puts("Round #{shape_idx}")
    end

    new_rock = create_shape(shape_idx, y + 4)

    {new_rocks, new_step} = rock_movement(new_rock, step, rock_set)
    new_y = find_highest_y(new_rocks)
    rock_round(new_rocks, new_y, shape_idx + 1, new_step, Map.put(y_map, shape_idx + 1, new_y))
  end

  @spec find_highest_y(all_rocks()) :: height()
  def find_highest_y(rock_set) do
    {_x, y} = Enum.max_by(rock_set, fn {_x, y} -> y end)
    y
  end

  @spec rock_movement(rock(), jet_step(), all_rocks()) :: all_rocks()
  def rock_movement(rock, step, rock_set) do
    dir = String.at(@jet_sample, rem(step, @jet_size))

    jet_rock =
      if valid_move?(rock, dir, rock_set) do
        move_rock(rock, dir)
      else
        rock
      end

    if valid_move?(jet_rock, "v", rock_set) do
      jet_rock
      |> move_rock("v")
      |> rock_movement(step + 1, rock_set)
    else
      {MapSet.union(rock_set, jet_rock), step + 1}
    end
  end

  @spec move_rock(rock(), direction()) :: rock()
  def move_rock(rock, dir) do
    {dx, dy} =
      case dir do
        "<" -> {-1, 0}
        ">" -> {1, 0}
        "v" -> {0, -1}
      end

    Enum.map(rock, fn {x, y} -> {x + dx, y + dy} end) |> MapSet.new()
  end

  @spec valid_move?(rock(), direction(), all_rocks()) :: boolean()
  def valid_move?(rock, dir, rock_set) do
    {dx, dy} =
      case dir do
        "<" -> {-1, 0}
        ">" -> {1, 0}
        "v" -> {0, -1}
      end

    new_rock = Enum.map(rock, fn {x, y} -> {x + dx, y + dy} end) |> MapSet.new()

    result =
      MapSet.disjoint?(new_rock, rock_set) and
        not Enum.any?(new_rock, fn {x, _} -> x > 6 or x < 0 end)

    result
  end

  @spec create_shape(shape_step(), height()) :: rock()
  def create_shape(shape_idx, y) do
    shapes = [&hor_shape/1, &cross_shape/1, &l_shape/1, &vert_shape/1, &box_shape/1]
    Enum.at(shapes, rem(shape_idx, 5)).({2, y}) |> MapSet.new()
  end

  @spec hor_shape(point()) :: list(point())
  def hor_shape({x, y}), do: [{x, y}, {x + 1, y}, {x + 2, y}, {x + 3, y}]

  @spec cross_shape(point()) :: list(point())
  def cross_shape({x, y}),
    do: [{x + 1, y}, {x + 1, y + 1}, {x + 1, y + 2}, {x, y + 1}, {x + 2, y + 1}]

  @spec l_shape(point()) :: list(point())
  def l_shape({x, y}), do: [{x, y}, {x + 1, y}, {x + 2, y}, {x + 2, y + 1}, {x + 2, y + 2}]

  @spec vert_shape(point()) :: list(point())
  def vert_shape({x, y}), do: [{x, y}, {x, y + 1}, {x, y + 2}, {x, y + 3}]

  @spec box_shape(point()) :: list(point())
  def box_shape({x, y}), do: [{x, y}, {x + 1, y}, {x, y + 1}, {x + 1, y + 1}]
end
