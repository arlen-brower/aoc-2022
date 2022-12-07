defmodule DaySeven do
  @threshold_size 100_000

  def run(input_path \\ "test_input") do
    lines =
      File.read!(input_path)
      |> String.split("\n", trim: true)

    IO.inspect(lines)
    parser(lines, 0, [])
  end

  def parser([], file_system, _cwd), do: file_system

  def parser([current | rest], file_system, cwd) do
    IO.puts(current)

    case current do
      "$ cd .." ->
        [cur_dir | parent_dirs] = cwd
        IO.puts("\tChanging directory to " <> hd(parent_dirs))
        parser(rest, file_system, parent_dirs)

      "$ cd" <> args ->
        IO.puts("\tChanging directory to " <> args)
        parser(rest, file_system, [args | cwd])

      "$ ls" <> _args ->
        IO.puts("\tDirectory " <> to_string(cwd) <> " contains:")
        {unparsed, dir_size} = list_dir(rest, [], 0)
        IO.puts("\t\t TOTAL: #{dir_size}")

        if dir_size <= @threshold_size do
          parser(unparsed, file_system + dir_size, cwd)
        else
          parser(unparsed, file_system, cwd)
        end
    end
  end

  def list_dir([], files, dir_size), do: {[], dir_size}
  def list_dir(["$" <> _ | _] = lines, files, dir_size), do: {lines, dir_size}

  def list_dir([current | rest], files, dir_size) do
    file_size =
      case Regex.run(~r/(\d+) .*/, current, capture: :all_but_first) do
        [x] ->
          String.to_integer(x)

        _ ->
          0
      end

    IO.puts("\t\t" <> current)
    list_dir(rest, [current | files], file_size + dir_size)
  end
end
