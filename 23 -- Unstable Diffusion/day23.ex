defmodule Day23 do
  @dir_list [[:n, :s, :w, :e], [:s, :w, :e, :n], [:w, :e, :n, :s], [:e, :n, :s, :w]]

  def run(file_path \\ "test_input") do
    file_path
    |> read_file()
    |> do_round(0, %{})
  end

  def calc_rectangle(elves) do
    rows = Enum.map(elves, fn {{r, _c}, _} -> r end)
    cols = Enum.map(elves, fn {{_r, c}, _} -> c end)

    min_r = Enum.min(rows)
    max_r = Enum.max(rows)

    min_c = Enum.min(cols)
    max_c = Enum.max(cols)
    l = abs(min_r - max_r) + 1
    w = abs(min_c - max_c) + 1

    l * w - map_size(elves)
  end

  def do_round(elves, round, elves), do: round

  def do_round(elves, round, last_elves) do
    if round == 10 do
      IO.puts("Round 10 empty squares: #{calc_rectangle(elves)}")
    end

    proposed_positions =
      elves
      |> Enum.reduce(%{}, fn {old_pos, _}, acc ->
        propose_position(elves, old_pos, Enum.at(@dir_list, rem(round, 4)))
        |> add_proposed(acc, old_pos)
      end)

    valid_positions =
      Map.filter(proposed_positions, fn {_, elf_list} -> length(elf_list) == 1 end)

    invalid_positions =
      Map.reject(proposed_positions, fn {_, elf_list} -> length(elf_list) == 1 end)
      |> Map.values()
      |> List.flatten()

    Enum.reduce(invalid_positions, valid_positions, fn elf, valid -> Map.put(valid, elf, []) end)
    |> Enum.map(fn {pos, _} -> {pos, []} end)
    |> Map.new()
    |> do_round(round + 1, elves)
  end

  def add_proposed(new_pos, proposed, old_pos) do
    other_props = proposed[new_pos]
    other_props = if other_props == nil, do: [], else: other_props
    Map.put(proposed, new_pos, [old_pos | other_props])
  end

  def propose_position(elves, {elf_r, elf_c} = elf_pos, dir_list) do
    n = {elf_r - 1, elf_c}
    ne = {elf_r - 1, elf_c + 1}
    e = {elf_r, elf_c + 1}
    se = {elf_r + 1, elf_c + 1}
    s = {elf_r + 1, elf_c}
    sw = {elf_r + 1, elf_c - 1}
    w = {elf_r, elf_c - 1}
    nw = {elf_r - 1, elf_c - 1}

    north_check = fn -> [n, ne, nw] |> Enum.any?(fn pos -> Map.has_key?(elves, pos) end) end

    south_check = fn -> [s, se, sw] |> Enum.any?(fn pos -> Map.has_key?(elves, pos) end) end

    west_check = fn -> [w, nw, sw] |> Enum.any?(fn pos -> Map.has_key?(elves, pos) end) end

    east_check = fn -> [e, ne, se] |> Enum.any?(fn pos -> Map.has_key?(elves, pos) end) end

    check_order =
      Enum.map(dir_list, fn
        :n -> !north_check.()
        :s -> !south_check.()
        :w -> !west_check.()
        :e -> !east_check.()
      end)

    go_to =
      Enum.map(dir_list, fn
        :n -> n
        :s -> s
        :w -> w
        :e -> e
      end)

    cond do
      Enum.all?(check_order) -> elf_pos
      Enum.at(check_order, 0) -> Enum.at(go_to, 0)
      Enum.at(check_order, 1) -> Enum.at(go_to, 1)
      Enum.at(check_order, 2) -> Enum.at(go_to, 2)
      Enum.at(check_order, 3) -> Enum.at(go_to, 3)
      true -> elf_pos
    end
  end

  def read_file(file_path) do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> parse_elves()
  end

  def parse_elves(elf_lines) do
    {parsed_elves, _} =
      Enum.reduce(elf_lines, {%{}, 1}, fn line, {elves, row} ->
        new_elves = parse_line(line, elves, row)
        {new_elves, row + 1}
      end)

    parsed_elves
  end

  def parse_line(line, elves, row) do
    {new_elves, _} =
      Enum.reduce(String.graphemes(line), {elves, 1}, fn tile, {elves, col} ->
        case tile do
          "." ->
            {elves, col + 1}

          "#" ->
            {Map.put(elves, {row, col}, []), col + 1}
        end
      end)

    new_elves
  end
end
