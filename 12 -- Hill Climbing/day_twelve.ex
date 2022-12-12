defmodule DayTwelve do
  @directions [{1, 0}, {0, 1}, {-1, 0}, {0, -1}]

  @type priority_queue() :: list(distance_data())
  @type distance() :: integer()
  @type elevation() :: integer()
  @type distance_data() :: tuple()
  @type path() :: String.t()
  @type row_id() :: integer()
  @type col_id() :: integer()
  @type links() :: list(distance_data())
  @type processed() :: list(point_data())
  @type point_data() :: tuple()
  @type row_map() :: %{col_id() => point_data()}
  @type height_map() :: %{row_id() => row_map()}

  @doc """
  Okay, so even though it looks like both parts are bring printed out
  it doesn't really work. You need to switch out lines 139 and 141 to
  use the correct 'linking' function.

  Also, I hate that linking function I made.
  """
  @spec run(path()) :: [part_one: distance(), part_two: distance()]
  def run(file_path \\ "test_input") do
    map =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.with_index()
      |> convert_to_map()
      |> add_start_and_end()

    first_map =
      map
      |> add_distance()
      |> dijkstra()

    part_one =
      with {r, c} <- first_map.end,
           {_height, distance} <- first_map[r][c],
           do: distance

    part_two =
      %{map | start: map.end, end: map.start}
      |> add_distance()
      |> dijkstra()
      |> Map.delete(:start)
      |> Map.delete(:end)
      |> Enum.map(fn {_idx, row_map} -> Map.values(row_map) end)
      |> List.flatten()
      |> Enum.filter(fn {elev, _dist} -> elev == ?a end)
      |> Enum.reduce([], fn {elev, dist}, acc ->
        if elev == ?a do
          [dist | acc]
        else
          acc
        end
      end)
      |> Enum.min()

    [part_one: part_one, part_two: part_two]
  end

  # =============================================

  @doc """
  Starts Dijkstra's algorithm off
  """
  @spec dijkstra(height_map()) :: height_map()
  def dijkstra(height_map) do
    start = {sr, sc} = height_map.start
    queue = q_push([], {0, start})

    update_distance(height_map, sr, sc, 0)
    |> do_dijkstra([], queue)
  end

  @doc """
  My weird Elixirfied interpretation of the algorithm. 
  Someone must have something far, far nicer.
  """
  @spec do_dijkstra(height_map(), processed(), priority_queue()) :: height_map()
  def do_dijkstra(height_map, _processed, []), do: height_map

  def do_dijkstra(height_map, processed, queue) do
    a = {ar, ac} = q_top(queue) |> elem(1)
    queue = q_pop(queue)

    unless a in processed do
      processed = [a | processed]

      get_neighbours(height_map, a)
      |> Enum.reduce(height_map, fn {{br, bc}, w}, distance ->
        if (distance[ar][ac] |> elem(1)) + w < distance[br][bc] |> elem(1) do
          updated_distance = update_distance(distance, br, bc, (distance[ar][ac] |> elem(1)) + w)

          do_dijkstra(
            updated_distance,
            processed,
            q_push(queue, {-(updated_distance[br][bc] |> elem(1)), {br, bc}})
          )
        else
          do_dijkstra(distance, processed, queue)
        end
      end)
    else
      do_dijkstra(height_map, processed, queue)
    end
  end

  @spec get_neighbours(height_map(), tuple()) :: links()
  def get_neighbours(height_map, {r, c}) do
    for {dr, dc} = dir <- @directions,
        is_suitable?(height_map, dir, r, c),
        do: {{dr + r, dc + c}, 1}
  end

  # =============================================
  # Dijkstra's calls for a priority queue. Ehhhh... good enough :)
  # =============================================
  @spec q_push(priority_queue(), term()) :: priority_queue()
  def q_push(queue, item), do: [item | queue]

  # I guess we could sort it like this if we REALLY wanted, but I think that's probably slower
  # |> Enum.sort_by(fn {dist, _pos} -> dist end, :desc)

  @spec q_top(priority_queue()) :: term()
  def q_top(queue), do: List.last(queue)

  @spec q_pop(priority_queue()) :: priority_queue()
  def q_pop(queue) do
    {_val, new_queue} = List.pop_at(queue, -1)
    new_queue
  end

  # =============================================
  @doc """
    Helper function to update a distance in the map for given row and column
  """
  @spec update_distance(height_map(), row_id(), col_id(), distance()) :: height_map()
  def update_distance(height_map, r, c, new_dist) do
    {ht, _old} = height_map[r][c]
    Map.put(height_map, r, Map.put(height_map[r], c, {ht, new_dist}))
  end

  @doc """
  Helper function that will probably break if used out of sequence :/
  Changes elevation data (used in add_start_and_end/1)
  """
  @spec update_elevation(height_map(), row_id(), col_id(), elevation()) :: height_map()
  def update_elevation(height_map, r, c, new_elev) do
    Map.put(height_map, r, Map.put(height_map[r], c, new_elev))
  end

  # =============================================

  @doc """
  Needs a real overhaul.
  Anyway, returns a boolean indicating links between points according to up/down logic
  """
  @spec is_suitable?(height_map(), tuple(), row_id(), col_id()) :: boolean()
  def is_suitable?(height_map, {r_mod, c_mod}, row_pos, col_pos) do
    current_height =
      case height_map[row_pos][col_pos] do
        {x, _dist} -> x
        nil -> nil
      end

    dir_height =
      case height_map[row_pos + r_mod][col_pos + c_mod] do
        {x, _dist} -> x
        nil -> nil
      end

    cur =
      cond do
        current_height == ?S -> ?a
        current_height == ?E -> ?z
        true -> current_height
      end

    dir =
      if dir_height == ?E do
        ?z
      else
        dir_height
      end

    # For part one to work :)
    #    dir_height != nil and dir - cur <= 1
    # Part two:
    dir_height != nil and cur - dir <= 1
  end

  # =============================================
  @spec convert_to_map(list(String.t())) :: height_map()
  def convert_to_map(map_list) do
    map_list
    |> Enum.reduce(%{}, fn {map_string, row}, height_map ->
      # For every row, convert it into a map, then put it into our overall heightmap
      row_map = string_to_map(map_string)

      Map.put(height_map, row, row_map)
    end)
  end

  @spec string_to_map(String.t()) :: row_map()
  def string_to_map(map_string) do
    # Get the charlist, since that'll be easy for comparisons
    len = String.length(map_string) - 1
    string_tup = String.to_charlist(map_string) |> List.to_tuple()

    Enum.reduce(0..len, %{}, fn col, string_map ->
      Map.put(string_map, col, elem(string_tup, col))
    end)
  end

  # =============================================

  @doc """
  Searches the map for start and end nodes, adds them as keys to the map
  Also replaces them with elevation data instead, now that we know the 
  positions.
  """
  @spec add_start_and_end(height_map()) :: height_map()
  def add_start_and_end(height_map) do
    rows = map_size(height_map) - 1

    # I mean, this is basically just a nested For loop
    updated =
      Enum.reduce(0..rows, height_map, fn r, h_map ->
        cols = map_size(h_map[r]) - 1

        Enum.reduce(0..cols, h_map, fn c, acc ->
          cond do
            acc[r][c] == ?S ->
              Map.put(acc, :start, {r, c})

            acc[r][c] == ?E ->
              Map.put(acc, :end, {r, c})

            true ->
              acc
          end
        end)
      end)

    {sr, sc} = updated.start
    {er, ec} = updated.end

    updated
    |> update_elevation(sr, sc, ?a)
    |> update_elevation(er, ec, ?z)
  end

  @doc """
  Should really be called 'reset' distance now
  """
  @spec add_distance(height_map()) :: height_map()
  def add_distance(%{start: _start, end: _stop} = height_map) do
    # -3 because of start and stop
    rows = map_size(height_map) - 3

    Enum.reduce(0..rows, height_map, fn r, h_map ->
      cols = map_size(h_map[r]) - 1

      Enum.reduce(0..cols, h_map, fn c, acc ->
        ht = acc[r][c]
        Map.put(acc, r, Map.put(acc[r], c, {ht, :inf}))
      end)
    end)
  end
end
