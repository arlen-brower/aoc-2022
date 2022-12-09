defmodule RopeServer do
  @num_knots 10

  @type coords() :: tuple()
  @type rope() :: list(coords())
  @type rope_state() :: %{rope: rope(), counter: integer()}

  @spec start() :: pid()
  def start() do
    init_rope = for _ii <- 1..@num_knots, do: {0, 0}
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
    {r, c} = hd(state.rope)

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

    {pos, rope} = update_rope(tl(state.rope), [new_head])

    new_state = %{
      state
      | rope: rope,
        positions: Map.put(state.positions, pos, :visited)
    }

    loop(new_state)
  end

  @spec update_position(coords(), coords()) :: coords()
  def update_position({new_row, new_col}, {cur_row, cur_col}) do
    {dif_row, dif_col} = {new_row - cur_row, new_col - cur_col}

    if abs(dif_row) > 1 or abs(dif_col) > 1 do
      dif_row = Integer.digits(dif_row, 2) |> hd()
      dif_col = Integer.digits(dif_col, 2) |> hd()
      {cur_row + dif_row, cur_col + dif_col}
    else
      {cur_row, cur_col}
    end
  end

  @spec update_rope(rope(), rope()) :: rope()
  def update_rope([], [new_pos | _] = updated_rope),
    do: {new_pos, Enum.reverse(updated_rope)}

  def update_rope([cur_pos | tail], [new_pos | _] = updated_rope) do
    update_rope(tail, [update_position(new_pos, cur_pos) | updated_rope])
  end
end
