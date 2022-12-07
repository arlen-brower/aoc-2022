defmodule DaySeven do
  defstruct lines: [], total: 0, target: 0

  @threshold_size 100_000
  @capacity 70_000_000
  @required 30_000_000

  def run(input_path \\ "test_input") do
    input =
      File.read!(input_path)
      |> String.split("\n", trim: true)

    results = parser(%__MODULE__{lines: input})
    target_size = @required - (@capacity - results.total)

    part_two =
      get_messages()
      |> Enum.filter(fn x -> x >= target_size end)
      |> Enum.min()

    [part_one: results.target, part_two: part_two]
  end

  # Recursive parsing function-------------------------------

  def parser(%{lines: []} = results), do: results

  def parser(%{lines: ["$ cd .." | rest]} = go_up),
    do: %{go_up | lines: rest}

  def parser(%{lines: ["$ cd " <> _dir | rest], total: total, target: target} = fs) do
    %{fs | lines: rest, total: 0}
    |> list_dir()
    |> parser()
    |> update_target()
    |> update_total(total)
    |> send_total()
    |> parser()
  end

  # Map helper functions -------------------------------------

  def send_total(%{} = fs), do: send(self(), fs)

  def update_total(%{} = fs, add), do: Map.update!(fs, :total, fn x -> x + add end)

  def update_target(%{} = fs) do
    Map.update!(fs, :target, fn t ->
      if fs.total <= @threshold_size do
        t + fs.total
      else
        t
      end
    end)
  end

  # Directory Size -----------------------------------------
  def list_dir(%{lines: []} = fs), do: fs
  def list_dir(%{lines: ["$ cd" <> _ | _]} = fs), do: fs
  def list_dir(%{lines: ["$ ls" | rest]} = fs), do: list_dir(%{fs | lines: rest})
  def list_dir(%{lines: ["dir " <> _ | rest]} = fs), do: list_dir(%{fs | lines: rest})

  def list_dir(%{lines: [current | rest], total: dir_size} = fs) do
    [file_size] = Regex.run(~r/(\d+) .*/, current, capture: :all_but_first)

    %{fs | lines: rest, total: String.to_integer(file_size) + dir_size}
    |> list_dir()
  end

  # Message loop --------------------------------------------

  def get_messages(messages \\ []) do
    receive do
      x -> get_messages([x.total | messages])
    after
      0 -> messages
    end
  end
end
