defmodule DayTwenty do
  def run(file_path \\ "test_input") do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.to_integer/1)
    |> mix_file()
    |> find_coords()
  end

  def find_coords(mixed_list) do
    len = length(mixed_list)

    out_list = Enum.reduce(mixed_list, "", fn x, acc -> acc <> Integer.to_string(x) <> "\n" end)
    File.write!("out", out_list, [:write])

    zero_idx = Enum.find_index(mixed_list, &(&1 == 0))

    first = Enum.at(mixed_list, rem(1000 + zero_idx, len))
    second = Enum.at(mixed_list, rem(2000 + zero_idx, len))
    third = Enum.at(mixed_list, rem(3000 + zero_idx, len))

    IO.puts("Coordinates are #{first}, #{second}, #{third}")
    IO.puts("Sum: #{first + second + third}")
  end

  def mix_file(mix_list) do
    [start | rest] = for n <- 0..(length(mix_list) - 1), do: n

    if length(mix_list) < 10 do
      IO.inspect(mix_list)
    end

    # IO.inspect(Enum.at(mix_list, start))

    {new_list, new_pos} = mix_it(mix_list, start)

    # IO.inspect(Enum.map(pos, fn id -> Enum.at(mix_list, id) end))
    # IO.inspect({new_list, new_pos})
    mix_file(new_list, update_positions(rest, new_pos, start, length(mix_list)))
  end

  def mix_file(mix_list, []), do: mix_list |> IO.inspect()

  def mix_file(mix_list, [next | rest]) do
    # IO.puts("#{length(rest)} remaining")

    {new_list, new_pos} = mix_it(mix_list, next)

    if length(mix_list) < 10 do
      IO.inspect(mix_list)
    end

    # IO.inspect(Enum.at(mix_list, next))
    updated_pos = update_positions(rest, new_pos, next, length(mix_list))

    # debug_left = Enum.map(rest, fn id -> Enum.at(mix_list, id) end)
    # debug_right = Enum.map(updated_pos, fn id -> Enum.at(new_list, id) end)
    #
    # if debug_left != debug_right do
    #   IO.puts("Error at #{next}")
    #   raise "oh no"
    # end

    mix_file(new_list, updated_pos)
  end

  def mix_it(encrypted, cur) do
    len = length(encrypted)

    case List.pop_at(encrypted, cur) do
      {val, lis} ->
        cond do
          val == 0 or val == len ->
            {encrypted, cur}

          abs(val) < len and val + cur <= 0 ->
            new_pos = rem(val + cur, len) - 1
            {List.insert_at(lis, new_pos, val), new_pos}

          abs(val) < len and val + cur >= len ->
            new_pos = rem(val + cur, len) + 1
            {List.insert_at(lis, new_pos, val), new_pos}

          true ->
            new_pos = rem(val + cur, len)
            {List.insert_at(lis, new_pos, val), new_pos}
        end
    end
  end

  def update_positions(positions, same, same, _len), do: positions

  def update_positions(positions, new_pos, old_pos, len) do
    new_pos =
      if new_pos < 0 do
        len + new_pos
      else
        new_pos
      end

    Enum.map(positions, fn idx ->
      cond do
        old_pos > new_pos and idx < old_pos and idx >= new_pos ->
          idx + 1

        new_pos > old_pos and idx <= new_pos and idx > old_pos ->
          idx - 1

        true ->
          idx
      end
    end)
  end
end
