defmodule DayTen do
  @cycles [20, 60, 100, 140, 180, 220]
  @screen_width 40

  @type noop() :: :noop
  @type addx() :: {:addx, integer()}
  @type instruction() :: noop() | addx()

  def run(file_path \\ "test_input") do
    start()

    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.each(fn cmd -> send(:comms, cmd) end)

    send(:comms, {:done, self()})

    results =
      receive do
        {:response, state} -> state
      after
        1_000 -> nil
      end

    part_one =
      results.signals
      |> Map.values()
      |> Enum.sum()

    part_two = results.screen

    IO.puts("Signal Sum: #{part_one}")
    print(part_two)
  end

  def print(screen) do
    screen
    |> Enum.reverse()
    |> Enum.chunk_every(40)
    |> Enum.each(&IO.puts(&1))
  end

  def start() do
    pid = spawn(fn -> loop(%{x: 1, signals: %{}, cycles: 1, screen: []}) end)

    try do
      pid
      |> Process.register(:comms)
    rescue
      ArgumentError ->
        Process.unregister(:comms)

        pid
        |> Process.register(:comms)
    end
  end

  def loop(%{} = state) do
    IO.inspect(state.x)

    new_state =
      receive do
        "addx " <> x ->
          state
          |> add_cycles()
          |> check_signal()
          |> add_x(String.to_integer(x))
          |> add_cycles()

        "noop" ->
          state
          |> add_cycles()

        {:done, caller} ->
          send(caller, {:response, state})
          state
      end

    new_state
    |> check_signal()
    |> loop()
  end

  def add_x(%{x: x} = state, add), do: %{state | x: x + add}
  # def add_cycles(%{cycles: cycle, screen: screen}, x: x)
  def add_cycles(%{cycles: cycle, x: x, screen: screen} = state, add \\ 1) do
    pixel =
      if rem(cycle, @screen_width) in (x - 1)..(x + 1) do
        "#"
      else
        " "
      end

    %{state | screen: [pixel | screen], cycles: cycle + add}
  end

  def check_signal(%{cycles: cycle, signals: signals, x: x} = state) when cycle in @cycles,
    do: %{state | signals: Map.put(signals, cycle, cycle * x)}

  def check_signal(%{} = state), do: state
end
