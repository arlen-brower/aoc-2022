defmodule Day25 do
  @max_len 20
  # @target 4890
  @target 30_638_862_852_576
  @symbol %{0 => "0", 1 => "1", 2 => "2", 3 => "=", 4 => "-"}

  def sum_snafu(snafu_list) do
    snafu_list
    |> Enum.map(&snafu_to_decimal/1)
    |> Enum.sum()
  end

  def decimal_to_snafu(decimal), do: decimal_to_snafu(decimal, [], 0)

  def decimal_to_snafu(0, build, 0), do: build |> List.to_string()
  def decimal_to_snafu(0, build, 1), do: ["1" | build] |> List.to_string()

  def decimal_to_snafu(decimal, build, carry) when decimal < 5 do
    final =
      if decimal + carry > 2 do
        ["1" <> @symbol[decimal + carry] | build]
      else
        [@symbol[decimal + carry] | build]
      end

    final |> List.to_string()
  end

  def decimal_to_snafu(decimal, build, carry) do
    quotient = div(decimal, 5)
    remainder = rem(decimal, 5)
    mod = [@symbol[rem(decimal + carry, 5)] | build]
    new_carry = if remainder + carry > 2, do: 1, else: 0

    decimal_to_snafu(quotient, mod, new_carry)
  end

  def snafu_to_decimal(snafu) do
    graphemes = String.graphemes(snafu)
    len = length(graphemes) - 1

    parsed =
      for n <- 0..len do
        place = 5 ** (len - n)

        val =
          case Enum.at(graphemes, n) do
            "2" -> 2
            "1" -> 1
            "0" -> 0
            "-" -> -1
            "=" -> -2
          end

        result = place * val
      end

    Enum.sum(parsed)
  end

  def brute_force(target \\ @target, debug \\ nil) do
    Enum.reduce_while(Stream.cycle([nil]), {1, "1"}, fn nil, {round, snafu} ->
      if debug != nil and rem(round, 10000) == 0, do: IO.puts("#{round}")
      added = add_one_snafu(snafu)
      if snafu_to_decimal(added) == target, do: {:halt, added}, else: {:cont, {round + 1, added}}
    end)
  end

  def add_one_snafu(""), do: "1"

  def add_one_snafu(snafu) do
    len = String.length(snafu)

    case String.last(snafu) do
      "=" ->
        String.slice(snafu, 0, len - 1) <> "-"

      "-" ->
        String.slice(snafu, 0, len - 1) <> "0"

      "0" ->
        String.slice(snafu, 0, len - 1) <> "1"

      "1" ->
        String.slice(snafu, 0, len - 1) <> "2"

      "2" ->
        add_one_snafu(String.slice(snafu, 0, len - 1)) <> "="
    end
  end
end
