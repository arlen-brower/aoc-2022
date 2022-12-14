defmodule DaySixteen do
  @time 30
  @training_time 4

  def spam(file_path \\ "input", runs \\ 1000),
    do:
      Enum.reduce(1..runs, [], fn _run, acc -> [run(file_path) |> IO.inspect() | acc] end)
      |> Enum.max()

  def run(file_path \\ "test_input") do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> parse_lines()
    |> save_elephants()
  end

  def save_elephants(valves) do
    dists = start_bfs(valves, :AA)
    pri = priority_list(dists)

    # [part_one: next(dists, pri, [], @time, 0, 0), part_two: new_next(dists)]
    new_next(dists)
  end

  def new_next(valves) do
    dists = start_bfs(valves, :AA)
    pri = priority_list(dists)

    len = length(pri)

    my_effort = %{valves: dists, time: @time - @training_time, rate: 0, total: 0}
    el_effort = %{valves: dists, time: @time - @training_time, rate: 0, total: 0}

    state = %{me: my_effort, ele: el_effort, open: []}

    new_state =
      Enum.reduce(1..len, state, fn _, cur_state ->
        ele_time = cur_state.ele.time
        me_time = cur_state.me.time

        cur_state
        |> player_move(:me)
        |> player_move(:ele)
      end)

    new_state.me.time * new_state.me.rate + new_state.me.total +
      new_state.ele.time * new_state.ele.rate + new_state.ele.total
  end

  def find_pri(_, [], _), do: []

  def find_pri(valves, [best | rest], time) do
    time_taken = valves[best].distance + 1

    if time_taken > time do
      find_pri(valves, rest, time)
    else
      best
    end
  end

  def player_move(state, player) do
    p = state[player]
    open = state.open
    pri = p.valves |> priority_list(open)
    pri = find_pri(p.valves, pri, p.time)

    unless pri == [] do
      best = pri
      time_taken = p.valves[best].distance + 1

      new_v = start_bfs(p.valves, best)
      flow_rate = p.valves[best].rate

      updated_player = %{
        valves: new_v,
        time: p.time - time_taken,
        rate: flow_rate + p.rate,
        total: p.total + p.rate * time_taken
      }

      state
      |> Map.put(player, updated_player)
      |> Map.put(:open, [best | open])
    else
      state
    end
  end

  def next(_valves, _pri, _open, 0, _flow_rate, total), do: total

  def next(valves, [], open, time, flow_rate, total),
    do: next(valves, [], open, time - 1, flow_rate, total + flow_rate)

  def next(valves, [best | rest], open, time, flow_rate, total) do
    # Travel time and opening time
    time_taken = valves[best].distance + 1

    if time_taken < time do
      dists = start_bfs(valves, best)

      pri =
        dists
        |> priority_list()
        |> Enum.reject(fn x -> x in open end)

      next(
        dists,
        pri,
        [best | open],
        time - time_taken,
        valves[best].rate + flow_rate,
        total + flow_rate * time_taken
      )
    else
      next(valves, rest, open, time, flow_rate, total)
    end
  end

  def priority_list(valves, reject \\ []) do
    pri_list =
      valves
      |> Enum.map(fn {label, valve} ->
        {label,
         unless valve.distance == 0 do
           valve.rate / valve.distance + :rand.uniform(3)
         else
           0
         end}
      end)
      |> Enum.sort_by(fn {_, dist} -> dist end, :desc)
      |> Enum.reject(fn {_, dist} -> dist == 0 end)
      |> Enum.map(fn {label, _} -> label end)
      |> Enum.reject(fn x -> x in reject end)
  end

  def bfs_dist(valves, start, [], distance), do: distance + valves[start].distance

  def bfs_dist(valves, start, goals, distance) do
    dists = start_bfs(valves, start)

    Enum.map(goals, fn st ->
      bfs_dist(dists, st, goals -- [st], valves[st].distance + distance)
    end)
    |> Enum.min()
  end

  def start_bfs(valves, start) do
    valves[start]
    |> Map.put(:visited, true)
    |> Map.put(:distance, 0)
    |> update_valves(start, valves)
    |> bfs([start])
    |> reset_visited()
  end

  def bfs(valves, []), do: valves

  def bfs(valves, q) do
    s = q_front(q)
    q = q_pop(q)

    {new_valves, new_q} =
      Enum.reduce(valves[s].adjacent, {valves, q}, fn u, {v_acc, q_acc} ->
        unless v_acc[u].visited do
          updated_v =
            v_acc[u]
            |> Map.put(:visited, true)
            |> Map.put(:distance, v_acc[s].distance + 1)
            |> Map.put(:path, q_push(v_acc[s].path, u))
            |> update_valves(u, v_acc)

          {updated_v, q_push(q_acc, u)}
        else
          {v_acc, q_acc}
        end
      end)

    bfs(new_valves, new_q)
  end

  def q_front(queue), do: List.first(queue)
  def q_push(queue, label), do: queue ++ [label]

  def q_pop(queue) do
    {_, new_q} = List.pop_at(queue, 0)
    new_q
  end

  def reset_visited(valves, ignore \\ []) do
    Enum.reduce(valves, valves, fn {label, valve}, acc ->
      if label in ignore do
        acc
      else
        update_valves(%{valve | visited: false}, label, acc)
      end
    end)
  end

  def update_valves(valve, label, valves) do
    Map.put(valves, label, valve)
  end

  def parse_lines(lines),
    do: Enum.reduce(lines, %{}, fn line, acc -> parse_line(acc, line) end)

  @pattern ~r/^Valve (..) has flow rate=(\d+); tunnels? leads? to valves? (.*)$/
  def parse_line(valve_map, line) do
    [label, rate, adjacent] = Regex.run(@pattern, line, capture: :all_but_first)

    Map.put(valve_map, String.to_atom(label), %{
      rate: String.to_integer(rate),
      adjacent: adjacent |> String.split(", ") |> Enum.map(&String.to_atom/1),
      distance: :inf,
      visited: false,
      path: []
    })
  end
end
