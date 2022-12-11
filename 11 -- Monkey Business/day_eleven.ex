defmodule DayEleven do
  @rounds 20
  @monkey_format "Monkey "
  @items_format "  Starting items: "
  @op_format "  Operation: new = "
  @div_format "  Test: divisible by "
  @true_format "    If true: throw to monkey "
  @false_format "    If false: throw to monkey "

  @type path() :: String.t()
  @type item() :: integer()
  @type items() :: list(item())
  @type operation() :: function()
  @type divisor() :: integer()
  @type monkey_id() :: integer()
  @type monkey() :: %{
          items: items(),
          op: operation(),
          div: divisor(),
          true_to: monkey_id(),
          false_to: monkey_id(),
          inspected: integer()
        }
  @type monkey_map() :: %{monkey_id() => monkey()}

  @spec run(path(), integer()) :: integer()
  def run(file_path \\ "test_input", rounds \\ @rounds) do
    file_path
    |> File.read!()
    |> String.split("\n\n", trim: true)
    |> Enum.map(&String.split(&1, "\n", trim: true))
    |> Enum.reduce(%{}, fn x, acc -> parse_monkey(x, acc) end)
    |> monkey_business(rounds)
    |> Enum.map(fn {_ii, monkey} -> monkey.inspected end)
    |> Enum.sort(:desc)
    |> Enum.take(2)
    |> Enum.reduce(fn x, acc -> x * acc end)
  end

  def monkey_business(monkey_map, 0), do: monkey_map

  def monkey_business(monkey_map, rounds) do
    num_monkeys = map_size(monkey_map)
    IO.write("Rounds to go: ")
    IO.inspect(rounds)

    monkey_map
    |> round(0, num_monkeys)
    |> monkey_business(rounds - 1)
  end

  def round(monkey_map, num_monkeys, num_monkeys), do: monkey_map

  def round(monkey_map, current_monkey, num_monkeys) do
    monkey_map
    |> inspect_items(current_monkey)
    |> be_relieved(current_monkey)
    |> throw_items(current_monkey)
    |> round(current_monkey + 1, num_monkeys)
  end

  def inspect_items(monkey_map, cur) do
    Map.put(
      monkey_map,
      cur,
      Map.update!(monkey_map[cur], :inspected, &(&1 + Enum.count(monkey_map[cur].items)))
    )
    |> be_worried(cur)
  end

  def be_worried(monkey_map, cur) do
    monkey_map
    |> Map.put(
      cur,
      Map.update!(monkey_map[cur], :items, fn items ->
        Enum.map(items, fn x -> monkey_map[cur].ops.(x) end)
      end)
    )
  end

  def be_relieved(monkey_map, cur) do
    Map.put(
      monkey_map,
      cur,
      Map.update!(monkey_map[cur], :items, fn items -> relief(items) end)
    )
  end

  def throw_items(monkey_map, cur) do
    current_monkey = monkey_map[cur]
    items = current_monkey.items
    div = current_monkey.div
    true_to = current_monkey.true_to
    false_to = current_monkey.false_to

    new_map =
      items
      |> Enum.reduce(monkey_map, fn item, acc ->
        if rem(item, div) == 0 do
          throw_item(acc, item, true_to)
        else
          throw_item(acc, item, false_to)
        end
      end)

    Map.put(new_map, cur, Map.update!(new_map[cur], :items, fn _x -> [] end))
  end

  def throw_item(monkey_map, item, to) do
    Map.put(monkey_map, to, Map.update!(monkey_map[to], :items, fn items -> items ++ [item] end))
  end

  @spec relief(items()) :: items()
  def relief(items), do: Enum.map(items, &div(&1, 3))

  @spec parse_monkey(monkey_map(), list(String.t())) :: monkey()
  def parse_monkey(
        [monkey_num, items, operation, test, true_monkey, false_monkey] = _monkey_string,
        monkey_map
      ) do
    monkey = %{
      items: parse_items(items),
      ops: parse_op(operation),
      div: parse_div(test),
      true_to: parse_true(true_monkey),
      false_to: parse_false(false_monkey),
      inspected: 0
    }

    Map.put(
      monkey_map,
      parse_id(monkey_num),
      monkey
    )
  end

  @spec parse_false(String.t()) :: monkey_id()
  def parse_false(@false_format <> false_id), do: false_id |> String.to_integer()

  @spec parse_true(String.t()) :: monkey_id()
  def parse_true(@true_format <> true_id), do: true_id |> String.to_integer()

  @spec parse_div(String.t()) :: divisor()
  def parse_div(@div_format <> div), do: div |> String.to_integer()

  # Security vulnerabilites, woohoo!
  @spec parse_op(String.t()) :: operation()
  def parse_op(@op_format <> op_string),
    do: fn old -> Code.eval_string(op_string, old: old) |> elem(0) end

  @spec parse_items(String.t()) :: items()
  def parse_items(@items_format <> items_string),
    do: items_string |> String.split(", ") |> Enum.map(&String.to_integer/1)

  @spec parse_id(String.t()) :: monkey_id()
  def parse_id(@monkey_format <> id), do: id |> String.trim_trailing(":") |> String.to_integer()
end
