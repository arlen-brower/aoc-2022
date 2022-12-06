defmodule DaySix do
  def scan_signal(signal, signal_length), do: scan_signal(signal, signal_length, signal_length)

  def scan_signal(signal, signal_length, counter) do
    <<chunk::binary-size(signal_length), _rest::binary>> = signal

    len =
      chunk
      |> String.graphemes()
      |> Enum.uniq()
      |> Enum.count()

    case len do
      ^signal_length ->
        {counter, signal}

      _ ->
        <<_, rest::binary>> = signal
        scan_signal(rest, signal_length, counter + 1)
    end
  end
end
