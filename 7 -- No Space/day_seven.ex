defmodule DaySeven do
  @threshold_size 100_000
  @capacity 70_000_000
  @required 30_000_000
  @min 5_174_025

  def run(input_path \\ "test_input") do
    File.read!(input_path)
    |> String.split("\n", trim: true)
    |> do_parse()
  end

  def do_parse(lines) do
    {[], total, target} = parser(lines, 0, 0)
    [total: total, target: target]
  end

  def parser([], total, target_total), do: {[], total, target_total}
  def parser(["$ cd .." | rest], total, target_total), do: {rest, total, target_total}

  def parser([cd | rest], total, target_total) do
    {unparsed, dir_size} =
      tl(rest)
      |> list_dir(0)

    {next_lines, new_total, new_target_total} = parser(unparsed, dir_size, target_total)

    if new_total >= @min do
      IO.puts(new_total)
    end

    if new_total <= @threshold_size do
      parser(next_lines, new_total + total, new_target_total + new_total)
    else
      parser(next_lines, new_total + total, new_target_total)
    end
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
