defmodule RopeServer do
  @num_knots 10

  @type coords() :: tuple()
  @type rope() :: list(coords())
  @type rope_state() :: %{head: coords(), rope: rope(), counter: integer()}

  @spec start() :: pid()
  def start() do
    init_rope = for _ii <- 1..@num_knots, do: {0, 0}
    pid = spawn(fn -> loop(%{head: {0, 0}, rope: init_rope, positions: %{}}) end)

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
    head = {r, c} = state[:head]

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

    {pos, rope} = update_rope(tl(state.rope), head, [new_head])

    new_state = %{
      state
      | rope: rope,
        head: new_head,
        positions: Map.put(state.positions, pos, :visited)
    }

    loop(new_state)
  end

  @spec pull_rope?(coords(), coords()) :: boolean()
  def pull_rope?({new_row, new_col}, {old_row, old_col}) do
    :math.sqrt((new_row - old_row) ** 2 + (new_col - old_col) ** 2) |> floor() > 1
  end

  @spec update_position(coords(), coords(), coords()) :: coords()
  def update_position({new_row, new_col} = new_pos, {cur_row, cur_col} = cur_pos, old_pos) do
    if pull_rope?(new_pos, cur_pos) do
      case {new_row - cur_row, new_col - cur_col} do
        {1, 1} -> {cur_row + 1, cur_col + 1}
        {1, -1} -> {cur_row + 1, cur_col - 1}
        {-1, -1} -> {cur_row - 1, cur_col - 1}
        {-1, 1} -> {cur_row - 1, cur_col + 1}
        {2, 0} -> {cur_row + 1, cur_col}
        {2, 1} -> {cur_row + 1, cur_col + 1}
        {1, 2} -> {cur_row + 1, cur_col + 1}
        {2, 2} -> {cur_row + 1, cur_col + 1}
        {0, 2} -> {cur_row, cur_col + 1}
        {-2, 1} -> {cur_row - 1, cur_col + 1}
        {-1, 2} -> {cur_row - 1, cur_col + 1}
        {-2, 2} -> {cur_row - 1, cur_col + 1}
        {-2, 0} -> {cur_row - 1, cur_col}
        {-2, -1} -> {cur_row - 1, cur_col - 1}
        {-1, -2} -> {cur_row - 1, cur_col - 1}
        {-2, -2} -> {cur_row - 1, cur_col - 1}
        {0, -2} -> {cur_row, cur_col - 1}
        {2, -1} -> {cur_row + 1, cur_col - 1}
        {1, -2} -> {cur_row + 1, cur_col - 1}
        {2, -2} -> {cur_row + 1, cur_col - 1}
      end
    else
      cur_pos
    end
  end

  @spec update_rope(rope(), coords(), rope()) :: rope()
  def update_rope([], _old_pos, [new_pos | _] = updated_rope),
    do: {new_pos, Enum.reverse(updated_rope)}

  def update_rope([cur_pos | tail], old_pos, [new_pos | _] = updated_rope) do
    update_rope(tail, cur_pos, [update_position(new_pos, cur_pos, old_pos) | updated_rope])
  end
end
