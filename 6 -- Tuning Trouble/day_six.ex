defmodule DaySix do
  @packet ~r/..../
  @message ~r/............../
  @len 14

  def scan_signal(signal, counter \\ @len) do
    len =
      Regex.run(@message, signal)
      |> hd()
      |> String.graphemes()
      |> MapSet.new()
      |> MapSet.size()

    if len == @len do
      {counter, signal}
    else
      <<_, rest::binary>> = signal
      scan_signal(rest, counter + 1)
    end
  end
end
