defmodule DayFiveRe do
  alias StackServer

  @crate_format ~r/\s?(\s|\[)(.|\s)(\s|\])\s?/
  @move_format ~r/move (\d*) from (\d*) to (\d*)/

  def crate_sim(file_path) do
    [stacks, moves] =
      file_path
      |> File.read!()
      |> String.trim_trailing()
      |> String.split(~r/\n 1 .*\n\n/)

    crates = parse_stacks(stacks)

    {_, num_stacks} =
      crates
      |> hd()
      |> List.last()

    stack_ids = for key <- 1..num_stacks, into: %{}, do: {key, StackServer.start()}

    crates
    |> List.flatten()
    |> Enum.reverse()
    |> Enum.reject(fn {cargo, _stack} -> cargo == " " end)
    |> Enum.each(fn {cargo, stack} -> StackServer.add_one(cargo, stack_ids[stack]) end)

    move_list = parse_moves(moves, stack_ids)

    top_crates = for stack <- 1..num_stacks, do: StackServer.get_one(stack_ids[stack])
    top_crates |> Enum.join()
  end

  # Stack parsing
  def parse_stacks(stacks) do
    stacks
    |> String.split("\n")
    |> Enum.map(fn row -> String.replace(row, @crate_format, "\\2") end)
    |> Enum.map(fn row -> String.graphemes(row) |> Enum.with_index(1) end)
  end

  # Moves parsing
  def parse_moves(moves, stack_ids) do
    moves
    |> String.split("\n")
    |> Enum.map(&parse_move/1)
    |> Enum.map(fn [amount, from, to] ->
      Enum.each(1..amount, fn _ ->
        StackServer.get_one(stack_ids[from])
        |> StackServer.add_one(stack_ids[to])
      end)
    end)
  end

  def parse_move(move) do
    Regex.run(@move_format, move, capture: :all_but_first)
    |> Enum.map(&String.to_integer(&1))
  end
end
