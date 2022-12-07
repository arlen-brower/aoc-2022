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

  def parser(%{lines: ["$ cd " <> _dir | rest], total: total, target: target}) do
    {unparsed, dir_size} =
      tl(rest)
      |> list_dir(0)

    updated = parser(%{lines: unparsed, total: dir_size, target: target})

    updated =
      Map.update!(updated, :target, fn t ->
        if updated.total <= @threshold_size do
          t + updated.total
        else
          t
        end
      end)

    updated = %{updated | total: updated.total + total}

    send(self(), updated.total)
    parser(updated)
  end

  # Directory Size -----------------------------------------

  def list_dir([], dir_size), do: {[], dir_size}
  def list_dir(["$" <> _ | _] = lines, dir_size), do: {lines, dir_size}
  def list_dir(["dir " <> _ | rest], dir_size), do: list_dir(rest, dir_size)

  def list_dir([current | rest], dir_size) do
    [file_size] = Regex.run(~r/(\d+) .*/, current, capture: :all_but_first)

    list_dir(rest, String.to_integer(file_size) + dir_size)
  end

  # Message loop --------------------------------------------

  def get_messages(messages \\ []) do
    receive do
      x -> get_messages([x | messages])
    after
      0 -> messages
    end
  end
end
