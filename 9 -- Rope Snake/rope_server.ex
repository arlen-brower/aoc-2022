defmodule RopeServer do
  @type coords() :: tuple()
  @type rope() :: list(coords())
  @type rope_state() :: %{head: coords(), tail: coords(), counter: integer()}

  @spec start() :: pid()
  def start() do
    init_rope = for x <- 1..10, do: {0, 0}
    pid = spawn(fn -> loop(%{head: {0, 0}, tail: {0, 0}, positions: %{}}) end)

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
    {r, c} = state[:head]
    IO.inspect(%{head: state[:head], tail: state[:tail]})

    new_state =
      receive do
        {:move, "U"} ->
          %{state | head: {r + 1, c}}

        {:move, "D"} ->
          %{state | head: {r - 1, c}}

        {:move, "R"} ->
          %{state | head: {r, c + 1}}

        {:move, "L"} ->
          %{state | head: {r, c - 1}}

        {:count, caller} ->
          send(caller, state[:positions] |> map_size())
          state
      end

    new_state
    |> check_tail({r, c})
    |> loop()
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
