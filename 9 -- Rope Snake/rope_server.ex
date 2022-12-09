defmodule RopeServer do
  @num_knots 10

  @type coords() :: tuple()
  @type rope() :: list(coords())
  @type rope_state() :: %{head: coords(), tail: coords(), counter: integer()}

  @spec start() :: pid()
  def start() do
    init_rope = for x <- 1..@num_knots, do: {0, 0}
    pid = spawn(fn -> loop(%{rope: init_rope, positions: %{}}) end)

    try do
      pid
      |> Process.register(:rope)
    rescue
      ArgumentError ->
        Process.unregister(:rope)

        pid
        |> Process.register(:rope)
    end
  end

  @spec loop(rope_state()) :: rope_state()
  def loop(%{} = state) do
    {r, c} = state[:rope] |> hd()

    state[:positions]
    |> map_size()
    |> IO.inspect()

    new_head =
      receive do
        {:move, "U"} ->
          {r + 1, c}

        {:move, "D"} ->
          {r - 1, c}

        {:move, "R"} ->
          {r, c + 1}

        {:move, "L"} ->
          {r, c - 1}

        {:count, caller} ->
          send(caller, state[:positions] |> map_size())
          {r, c}
      end

    state[:rope]
    |> tl()
    |> update_rope([new_head], {r, c}, state)
    |> loop()

    # new_state
    # |> check_tail({r, c})
    # |> loop()
  end

  @spec update_rope(rope(), rope(), coords(), rope_state()) :: rope_state()
  def update_rope([], rope, _last, state), do: %{state | rope: Enum.reverse(rope)}

  def update_rope([current | tail], [head | _] = rope, {_, _} = last, state) do
    {hr, hc} = head
    {cr, cc} = current
    distance = :math.sqrt((hr - cr) ** 2 + (hc - cc) ** 2) |> floor()

    IO.inspect(tail)

    if distance > 1 do
      new_state =
        if tail == [] do
          IO.inspect(tail)
          Map.put(state[:positions], last, :visited)
        else
          state
        end

      update_rope(tail, [last | rope], current, new_state)
    else
      update_rope(tail, [current | rope], current, state)
    end
  end

  @spec check_tail(rope_state(), coords()) :: rope_state()
  def check_tail(
        %{head: {hr, hc}, tail: {tr, tc}, positions: count} = state,
        {old_r, old_c} = old
      ) do
    dr = hr - tr
    dc = hc - tc
    # Euclidean distance
    distance = :math.sqrt(dr ** 2 + dc ** 2) |> floor()

    if distance > 1 do
      # Move
      %{state | tail: old, positions: Map.put(count, {old_r, old_c}, :visited)}
    else
      state
    end
  end
end
