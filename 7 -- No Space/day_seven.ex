defmodule DaySeven do
  @threshold_size 100_000
  @capacity 70_000_000
  @required 30_000_000

  @type path :: String.t()
  @type data :: list(command() | file() | directory())
  @type command :: String.t()
  @type file :: String.t()
  @type directory :: String.t()
  @type file_size :: integer()
  @type filesystem :: %{lines: data(), total: file_size(), target: file_size()}

  @spec run(path()) :: [part_one: file_size, part_two: file_size()]
  def run(input_path \\ "test_input") do
    input =
      File.read!(input_path)
      |> String.split("\n", trim: true)

    results = parser(%{lines: input, total: 0, target: 0})
    target_size = @required - (@capacity - results.total)

    part_two =
      get_messages()
      |> Enum.filter(fn x -> x >= target_size end)
      |> Enum.min()

    [part_one: results.target, part_two: part_two]
  end

  # Recursive parsing function-------------------------------

  @spec parser(filesystem()) :: filesystem()
  def parser(%{lines: []} = results), do: results

  def parser(%{lines: ["$ cd .." | rest]} = go_up),
    do: %{go_up | lines: rest}

  def parser(%{lines: ["$ cd " <> _dir | rest], total: total} = fs) do
    %{fs | lines: rest, total: 0}
    |> list_dir()
    |> parser()
    |> update_target()
    |> update_total(total)
    |> send_total()
    |> parser()
  end

  # Directory Size -----------------------------------------
  @spec list_dir(filesystem()) :: filesystem()
  def list_dir(%{lines: []} = fs), do: fs
  def list_dir(%{lines: ["$ cd" <> _ | _]} = fs), do: fs
  def list_dir(%{lines: ["$ ls" | rest]} = fs), do: list_dir(%{fs | lines: rest})
  def list_dir(%{lines: ["dir " <> _ | rest]} = fs), do: list_dir(%{fs | lines: rest})

  def list_dir(%{lines: [current | rest], total: dir_size} = fs) do
    [file_size] = Regex.run(~r/(\d+) .*/, current, capture: :all_but_first)

    %{fs | lines: rest, total: String.to_integer(file_size) + dir_size}
    |> list_dir()
  end

  # Map helper functions -------------------------------------

  @spec send_total(filesystem()) :: filesystem()
  def send_total(%{} = fs), do: send(self(), fs)

  @spec update_total(filesystem(), file_size()) :: filesystem()
  def update_total(%{} = fs, add), do: Map.update!(fs, :total, fn x -> x + add end)

  @spec update_target(filesystem()) :: filesystem()
  def update_target(%{} = fs) do
    Map.update!(fs, :target, fn t ->
      if fs.total <= @threshold_size do
        t + fs.total
      else
        t
      end
    end)
  end

  # Message loop --------------------------------------------

  @spec get_messages([]) :: list(file_size())
  def get_messages(messages \\ []) do
    receive do
      x -> get_messages([x.total | messages])
    after
      0 -> messages
    end
  end
end
