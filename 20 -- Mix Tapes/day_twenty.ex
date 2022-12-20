defmodule DayTwenty do
  @decryption_key 811_589_153

  def run(file_path \\ "test_input") do
    encrypted =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.to_integer/1)

    part_one =
      encrypted
      |> mix_file()
      |> find_coords()

    part_two =
      encrypted
      |> Enum.map(fn x -> x * @decryption_key end)
      |> mix_file()
      |> multi_mix(9)
      |> find_coords()

    [part_one: part_one, part_two: part_two]
  end

  def multi_mix({encrypted, positions}, num_mix_times) do
    Enum.reduce(1..num_mix_times, {encrypted, positions}, fn i, {enc, mix_pos} ->
      {new_enc, new_positions} = mix_file(enc, mix_pos, [])
    end)
  end

  def find_coords({mixed_list, _}) do
    len = length(mixed_list)

    out_list = Enum.reduce(mixed_list, "", fn x, acc -> acc <> Integer.to_string(x) <> "\n" end)
    File.write!("out", out_list, [:write])

    zero_idx = Enum.find_index(mixed_list, &(&1 == 0))

    first = Enum.at(mixed_list, rem(1000 + zero_idx, len))
    second = Enum.at(mixed_list, rem(2000 + zero_idx, len))
    third = Enum.at(mixed_list, rem(3000 + zero_idx, len))

    IO.puts("Coordinates are #{first}, #{second}, #{third}")
    IO.puts("Sum: #{first + second + third}")
    first + second + third
  end

  def mix_file(mix_list) do
    [start | rest] = for n <- 0..(length(mix_list) - 1), do: n

    if length(mix_list) < 10 do
      IO.inspect(mix_list)
    end

    {new_list, new_pos} = mix_it(mix_list, start)
    updated_pos = update_positions(rest, new_pos, start, length(mix_list))

    mix_file(new_list, updated_pos, [new_pos])
  end

  def mix_file(mix_list, [], mix_pos), do: {mix_list, Enum.reverse(mix_pos)}

  def mix_file(mix_list, [next | rest], mix_pos) do
    {new_list, new_pos} = mix_it(mix_list, next)

    if length(mix_list) < 10 do
      IO.inspect(mix_list)
    end

    updated_pos = update_positions(rest, new_pos, next, length(mix_list))
    new_mix_pos = update_positions(mix_pos, new_pos, next, length(mix_list))

    cor_pos =
      if new_pos < 0 do
        length(mix_list) + new_pos
      else
        new_pos
      end

    mix_file(new_list, updated_pos, [cor_pos | new_mix_pos])
  end

  def mix_it(encrypted, cur) do
    len = length(encrypted)

    case List.pop_at(encrypted, cur) do
      {val, lis} ->
        cond do
          val == 0 or val == len ->
            {encrypted, cur}

          val + cur <= 0 ->
            new_pos = rem(val + cur, len - 1) - 1
            {List.insert_at(lis, new_pos, val), new_pos}

          true ->
            new_pos = rem(val + cur, len - 1)
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
