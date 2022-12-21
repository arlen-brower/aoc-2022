defmodule Day21 do
  @type path() :: String.t()
  @type comparison() :: neg_integer() | 0 | pos_integer()
  @type comparator() :: (integer() -> comparison())
  @type monkey_string() :: String.t()
  @type monkey_label() :: String.t()
  @type monkey_number() :: integer()
  @type monkey_op() :: String.t()
  @type monkey() :: %{one: monkey_label(), op: monkey_op(), two: monkey_label()}
  @type monkey_map() :: %{monkey_label() => monkey_number() | monkey()}

  @spec run(path()) :: [part_one: integer(), part_two: integer()]
  def run(file_path \\ "test_input") do
    monkey_map =
      file_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> create_monkey_map()

    part_one =
      monkey_map
      |> eval_monkey("root")
      |> Access.get("root")
      |> trunc()

    part_two =
      monkey_map
      |> eval_human()

    [part_one: part_one, part_two: part_two]
  end

  @doc """
  Recursively evaluate a monkey map. 
  Intended to be initially called as: eval_monkey(monkey_map, "root")
  """
  @spec eval_monkey(monkey_map(), monkey_label()) :: monkey_map()
  def eval_monkey(monkey_map, monkey_name) do
    monkey = monkey_map[monkey_name]

    if monkey |> is_map() do
      monkey_results =
        eval_monkey(monkey_map, monkey.one)
        |> eval_monkey(monkey.two)

      monkey_one = monkey_results[monkey.one]
      monkey_two = monkey_results[monkey.two]

      case monkey_map[monkey_name].op do
        "+" ->
          Map.put(monkey_results, monkey_name, monkey_one + monkey_two)

        "-" ->
          Map.put(monkey_results, monkey_name, monkey_one - monkey_two)

        "*" ->
          Map.put(monkey_results, monkey_name, monkey_one * monkey_two)

        "/" ->
          Map.put(monkey_results, monkey_name, div(monkey_one, monkey_two))
      end
    else
      monkey_map
    end
  end

  @doc """
  Evaluate the monkey_map according to the rules for Part Two.
  """
  @spec eval_human(monkey_map()) :: integer()
  def eval_human(monkey_map) do
    comp_fun = which_comparison(monkey_map)
    msd = find_most_significant(monkey_map, 0, comp_fun)
    radix_sift(monkey_map, 10 ** msd, msd, 0, comp_fun)
  end

  @doc """
  Evaluate the monkey_map using the given number.
  Returns:
    -- Negative number when left side is lower
    -- 0 when both sides match
    -- Positive number when left side is higher
  """
  @spec test_val(monkey_map(), integer()) :: comparison()
  def test_val(mm, number) do
    one = mm["root"].one
    two = mm["root"].two
    new_map = %{mm | "humn" => number} |> eval_monkey("root")
    new_map[one] - new_map[two]
  end

  @doc """
  Finds the most significant digit of the monkey answer for Part Two. 
  Works by checking to see if you cross the 'threshold' from the test_val function.

  I don't really like the comparison function here, but I just hastily added that 
  in so that the program would work with different inputs, not just my own.
  """
  @spec find_most_significant(monkey_map(), non_neg_integer(), comparator()) :: non_neg_integer()
  def find_most_significant(mm, digits, comp_fun \\ &(&1 > 0)) do
    if test_val(mm, 10 ** digits) |> comp_fun.() do
      find_most_significant(mm, digits + 1, comp_fun)
    else
      digits - 1
    end
  end

  @doc """
  Determines which comparison operation the program should use.
  i.e. if the input will generate a higher number on the 'left' or the 'right' of the root monkey
  """
  @spec which_comparison(monkey_map()) :: comparator()
  def which_comparison(monkey_map) do
    if test_val(monkey_map, 1) > 0 do
      &(&1 > 0)
    else
      &(&1 < 0)
    end
  end

  @doc """
  Sift through a number one place at a time until the correct answer is found
  """
  @spec radix_sift(monkey_map(), integer(), non_neg_integer(), 0..10, comparator()) :: integer()
  def radix_sift(_monkey_map, estimate, -1, _val, _), do: estimate

  def radix_sift(_monkey_map, estimate, 0, 10, _), do: estimate + 10

  def radix_sift(monkey_map, estimate, place, val, comp_fun) do
    t = test_val(monkey_map, estimate + 10 ** place * val)

    cond do
      t == 0 ->
        radix_sift(monkey_map, estimate + 10 ** place * val, place - 1, 0, comp_fun)

      t |> comp_fun.() ->
        radix_sift(monkey_map, estimate, place, val + 1, comp_fun)

      true ->
        radix_sift(monkey_map, estimate + 10 ** place * (val - 1), place - 1, 0, comp_fun)
    end
  end

  @doc """
  Given a list of monkey strings, create a map.
  i.e.
     ["root: pppw + sjmn",
      "dbpl: 5",
      ...]
  """
  @spec create_monkey_map(list(monkey_string())) :: monkey_map()
  def create_monkey_map(monkey_lines) do
    for line <- monkey_lines, into: %{}, do: parse_line(line)
  end

  @doc """
  Given a single monkey string, create either a map representing an Operation Monkey or a number
  """
  @pattern_op ~r/(.+): (.+) (\+?-?\/?\*?) (.+)/
  @pattern_num ~r/(.+): (\d+)/
  @spec parse_line(monkey_string()) :: monkey()
  def parse_line(monkey_line) do
    case Regex.run(@pattern_op, monkey_line, capture: :all_but_first) do
      [monkey_name, monkey_one, op, monkey_two] ->
        {monkey_name, %{one: monkey_one, op: op, two: monkey_two}}

      nil ->
        [monkey_name, num] = Regex.run(@pattern_num, monkey_line, capture: :all_but_first)
        {monkey_name, String.to_integer(num)}
    end
  end
end
