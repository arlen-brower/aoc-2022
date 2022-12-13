defmodule DayThirteen do
  def run(file_path \\ "test_input") do
    packets =
      file_path
      |> File.read!()
      |> String.split("\n\n", trim: true)
      |> Enum.map(&String.split(&1, "\n", trim: true))
      |> Enum.map(&eval_lists/1)

    part_one =
      packets
      |> Enum.map(fn [left, right] -> in_order?(left, right) end)
      |> Enum.with_index(1)
      |> Enum.filter(fn {order, _idx} -> order end)
      |> Enum.reduce(0, fn {_order, idx}, acc -> acc + idx end)

    part_two =
      packets
      |> Enum.reduce([], fn [l, r], acc -> [l | [r | acc]] end)
      |> Kernel.++([[[2]]])
      |> Kernel.++([[[6]]])
      |> Enum.sort(&in_order?/2)
      |> Enum.with_index(1)
      |> Enum.filter(fn {packet, _idx} -> packet == [[2]] or packet == [[6]] end)
      |> Enum.reduce(1, fn {_packet, idx}, acc -> acc * idx end)

    [part_one: part_one, part_two: part_two]
  end

  @doc """
  Watch what you put into this function. :-)
  """
  def eval_lists([left, right]) do
    [
      Code.eval_string(left)
      |> elem(0),
      Code.eval_string(right)
      |> elem(0)
    ]
  end

  def in_order?([], [_ | _]), do: true
  def in_order?([_ | _], []), do: false
  def in_order?([same | lrest], [same | rrest]), do: in_order?(lrest, rrest)

  def in_order?([left | lrest], [right | _] = r) when is_integer(left) and is_list(right),
    do: in_order?([[left] | lrest], r)

  def in_order?([left | _] = l, [right | rrest]) when is_list(left) and is_integer(right),
    do: in_order?(l, [[right] | rrest])

  def in_order?([left | _], [right | _]) when is_list(left) and is_list(right),
    do: in_order?(left, right)

  def in_order?(same, same), do: true
  def in_order?([left | _lrest], [right | _rrest]) when left < right, do: true
  def in_order?([left | _lrest], [right | _rrest]) when left > right, do: false
end
