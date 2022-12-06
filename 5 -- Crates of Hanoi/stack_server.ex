defmodule StackServer do
  @spec start() :: pid()
  def start do
    spawn(fn -> loop([]) end)
  end

  @spec loop(list(integer)) :: list(integer)
  def loop(stack) do
    new_stack =
      receive do
        {:push_one, value} ->
          [value | stack] |> IO.inspect()

        {:pop_one, caller} ->
          unless Enum.empty?(stack) do
            [top_crate | rest] = stack
            send(caller, {:response, top_crate})
            IO.inspect(rest)
            rest
          else
            send(caller, {:response, :empty})
            stack
          end

        {:inspect, caller} ->
          send(caller, {:response, stack})
          stack
      end

    loop(new_stack)
  end

  @spec get_one(pid()) :: String.t()
  def get_one(server_pid) do
    send(server_pid, {:pop_one, self()})

    receive do
      {:response, crate} ->
        crate
    after
      1_000 -> " "
    end
  end

  @spec add_one(pid(), String.t()) :: any()
  def add_one(crate, server_pid) do
    send(server_pid, {:push_one, crate})
  end
end
