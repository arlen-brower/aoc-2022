defmodule DayFive do
  @crate_format ~r/\s?(\s|\[)(.|\s)(\s|\])\s?/
  @move_format ~r/move (\d*) from (\d*) to (\d*)/

  def crate_sim(file_path) do
    [stacks, moves] =
      file_path
      |> File.read!()
      |> String.trim_trailing()
      |> String.split(~r/\n 1 .*\n\n/)

    crates = parse_stacks(stacks)
    move_list = parse_moves(moves)

    part_one =
      do_moves(crates, move_list)
      |> Enum.map(fn {_id, crates} -> hd(crates) end)
      |> Enum.join()

    part_two =
      do_moves(crates, move_list, big: true)
      |> Enum.map(fn {_id, crates} -> hd(crates) end)
      |> Enum.join()

    IO.puts(~c"""
    Cratemaster 9000: #{part_one}
    Cratemaster 9001: #{part_two}
    """)
  end

  def do_moves(crates, moves, opts \\ [])
  def do_moves(crates, [], _opts), do: crates
  def do_moves(crates, [[amount, from, to] | rest], opts) do
    crates
    |> move(amount, from, to, opts)
    |> do_moves(rest, opts)
  end

  # Stack parsing
  def parse_stacks(stacks) do
    stacks
    |> String.split("\n")
    |> Enum.map(fn row -> String.replace(row, @crate_format, "\\2") end)
    |> Enum.map(fn row -> String.graphemes(row) |> Enum.with_index(1) end)
    |> Enum.reverse()
    |> parse_rows(%{})
  end

  def parse_rows([], dict), do: dict
  def parse_rows([row | rest], dict) do
    dict = parse_row(row, dict)
    parse_rows(rest, dict)
  end

  def parse_row([], dict), do: dict
  def parse_row([{value, key} | tail], dict) do
    parse_row(tail, push(dict, key, value))
  end

  # Moves parsing
  def parse_moves(moves) do
    moves
    |> String.split("\n")
    |> Enum.map(&parse_move/1)
  end

  def parse_move(move) do
    Regex.run(@move_format, move, capture: :all_but_first)
    |> Enum.map(&String.to_integer(&1))
  end

  # Movement Functions
  def move(dict, amount, from, to, opts \\ [])
  def move(dict, 0, _from, _to, _opts), do: dict
  def move(dict, amount, from, to, big: true) do
    {crate, dict} = pop(dict, from, amount)
    push(dict, to, crate)
  end

  def move(dict, amount, from, to, _opts) do
    move(dict, from, to)
    |> move(amount - 1, from, to)
  end

  def move(dict, from, to) do
    {crate, dict} = pop(dict, from)
    push(dict, to, crate)
  end

  # Map Helpers
  def push(dict, _key, " "), do: dict
  def push(dict, key, value) when is_list(value) do
    Map.update(dict, key, value, fn x -> value ++ x end)
  end

  def push(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def pop(dict, key) do
    Map.get_and_update(dict, key, fn [head | tail] ->
      {head, tail}
    end)
  end

  def pop(dict, key, amount) do
    Map.get_and_update(dict, key, fn lis -> Enum.split(lis, amount) end)
  end
end
