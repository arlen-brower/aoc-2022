defmodule DayNine do
  alias RopeServer

  def run(file_path) do
    RopeServer.start()

    File.read!(file_path)
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split/1)
    |> Enum.map(fn [direction, amount] -> [direction, String.to_integer(amount)] end)
    |> Enum.map(fn [direction, amount] -> do_moves(direction, amount) end)

    send(:rope, {:count, self()})

    receive do
      x -> x
    after
      1_000 -> "Nothing"
    end
  end

  def do_moves(_direction, 0), do: nil

  def do_moves(direction, amount) do
    send(:rope, {:move, direction})
    do_moves(direction, amount - 1)
  end
end
