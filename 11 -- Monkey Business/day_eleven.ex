defmodule DayEleven do
  @rounds 10_000
  @lcm 9_699_690
  @monkey_format "Monkey "
  @items_format "  Starting items: "
  @op_format "  Operation: new = "
  @div_format "  Test: divisible by "
  @true_format "    If true: throw to monkey "
  @false_format "    If false: throw to monkey "

  @type path() :: String.t()
  @type item() :: integer()
  @type round() :: integer()
  @type items() :: list(item())
  @type operation() :: function()
  @type divisor() :: integer()
  @type monkey_id() :: integer()
  @type monkey() :: %{
          items: items(),
          ops: operation(),
          div: divisor(),
          true_to: monkey_id(),
          false_to: monkey_id(),
          inspected: integer()
        }
  @type monkey_map() :: %{monkey_id() => monkey(), lcm: integer()}

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
    |> Enum.product()
  end

  @spec monkey_business(monkey_map(), round()) :: monkey_map()
  def monkey_business(monkey_map, rounds) do
    num_monkeys = map_size(monkey_map)
    Enum.reduce(1..rounds, monkey_map, fn _, m_map -> round(m_map, 0, num_monkeys) end)
  end

  @spec round(monkey_map(), monkey_id(), integer()) :: monkey_map()
  def round(monkey_map, num_monkeys, num_monkeys), do: monkey_map

  def round(monkey_map, current_monkey, num_monkeys) do
    monkey_map
    |> inspect_items(current_monkey)
    |> be_worried(current_monkey)
    |> be_relieved(current_monkey)
    |> throw_items(current_monkey)
    |> round(current_monkey + 1, num_monkeys)
  end

  @spec update_monkeys(monkey(), monkey_id(), monkey_map()) :: monkey_map()
  def update_monkeys(monkey, cur, monkey_map) do
    Map.put(monkey_map, cur, monkey)
  end

  @spec inspect_items(monkey_map(), monkey_id()) :: monkey_map()
  def inspect_items(monkey_map, cur) do
    Map.update!(monkey_map[cur], :inspected, &(&1 + Enum.count(monkey_map[cur].items)))
    |> update_monkeys(cur, monkey_map)
  end

  @spec be_worried(monkey_map(), monkey_id()) :: monkey_map()
  def be_worried(monkey_map, cur) do
    Map.update!(monkey_map[cur], :items, fn items ->
      Enum.map(items, fn x -> monkey_map[cur].ops.(x) end)
    end)
    |> update_monkeys(cur, monkey_map)
  end

  @spec be_relieved(monkey_map(), monkey_id()) :: monkey_map()
  def be_relieved(monkey_map, cur) do
    Map.update!(monkey_map[cur], :items, fn items -> relief(items) end)
    |> update_monkeys(cur, monkey_map)
  end

  @spec throw_items(monkey_map(), monkey_id()) :: monkey_map()
  def throw_items(monkey_map, cur) do
    monkey = monkey_map[cur]
    items = monkey.items
    div = monkey.div
    true_to = monkey.true_to
    false_to = monkey.false_to

    new_map =
      items
      |> Enum.reduce(monkey_map, fn item, acc ->
        if rem(item, div) == 0 do
          throw_item(acc, item, true_to)
        else
          throw_item(acc, item, false_to)
        end
      end)

    Map.put(new_map, cur, Map.put(new_map[cur], :items, []))
  end

  @spec throw_item(monkey_map(), item(), monkey_id()) :: monkey_map()
  def throw_item(monkey_map, item, to) do
    Map.put(monkey_map, to, Map.update!(monkey_map[to], :items, fn items -> [item | items] end))
  end

  @spec relief(items()) :: items()
  # &div(&1, 3))
  def relief(items), do: Enum.map(items, &rem(&1, @lcm))

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
