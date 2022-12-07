defmodule DaySeven do
  @threshold_size 100_000
  @capacity 70_000_000
  @required 30_000_000

  def run(input_path \\ "test_input") do
    File.read!(input_path)
    |> String.split("\n", trim: true)
    |> do_parse()
  end

  def do_parse(lines) do
    {[], total, target} = parser(lines, 0, 0)
    target_size = @required - (@capacity - total)
    parser(lines, 0, 0, target_size)

    part_two =
      get_messages()
      |> Enum.min()

    [part_one: target, part_two: part_two]
  end

  def get_messages(messages \\ []) do
    receive do
      x -> get_messages([x | messages])
    after
      0 -> messages
    end
  end

  def parser(lines, total, target_total, delete_size \\ nil)
  def parser([], total, target_total, _delete_size), do: {[], total, target_total}

  def parser(["$ cd .." | rest], total, target_total, _delete_size),
    do: {rest, total, target_total}

  def parser(["$ cd " <> _dir | rest], total, target_total, delete_size) do
    {unparsed, dir_size} =
      tl(rest)
      |> list_dir(0)

    {next_lines, new_total, new_target_total} =
      parser(unparsed, dir_size, target_total, delete_size)

    if delete_size != nil and new_total >= delete_size do
      send(self(), new_total)
    end

    new_target_total =
      if new_total <= @threshold_size do
        new_target_total + new_total
      else
        new_target_total
      end

    parser(next_lines, new_total + total, new_target_total, delete_size)
  end

  def list_dir([], dir_size), do: {[], dir_size}
  def list_dir(["$" <> _ | _] = lines, dir_size), do: {lines, dir_size}

  def list_dir([current | rest], dir_size) do
    file_size =
      case Regex.run(~r/(\d+) .*/, current, capture: :all_but_first) do
        [x] ->
          String.to_integer(x)

        _ ->
          0
      end

    list_dir(rest, file_size + dir_size)
  end
end
