defmodule ExSPIKE.Frame do
  @moduledoc """
  Framing of raw message bytes for the wire.

  A frame is produced by COBS encoding the message (`ExSPIKE.COBS`), XORing
  every byte with `0x03` and appending the `0x02` end delimiter. High-priority
  frames are additionally prefixed with `0x01`.

  All functions are pure. When reading from a byte stream, keep the `rest`
  returned by `split/1` and prepend it to the next chunk of bytes you receive.
  """

  import Bitwise

  @high_priority 0x01
  @end_of_frame 0x02
  @xor 0x03

  @doc """
  Encodes and frames raw message bytes.

  ## Options

    * `:priority` - `:low` (default) or `:high`. High-priority frames are
      prefixed with `0x01`.

  ## Examples

      iex> ExSPIKE.Frame.pack(<<0x00>>)
      <<0x00, 0x00, 0x02>>

      iex> ExSPIKE.Frame.pack(<<0x00>>, priority: :high)
      <<0x01, 0x00, 0x00, 0x02>>
  """
  @spec pack(binary(), keyword()) :: binary()
  def pack(data, opts \\ []) when is_binary(data) do
    body = data |> ExSPIKE.COBS.encode() |> xor()

    case Keyword.get(opts, :priority, :low) do
      :low -> <<body::binary, @end_of_frame>>
      :high -> <<@high_priority, body::binary, @end_of_frame>>
    end
  end

  @doc """
  Splits a frame into BLE packets of at most `max_packet_size` bytes.

  Use the `max_packet_size` from the hub's `ExSPIKE.Message.InfoResponse`.

      iex> ExSPIKE.Frame.packets(<<1, 2, 3, 4, 5>>, 2)
      [<<1, 2>>, <<3, 4>>, <<5>>]
  """
  @spec packets(binary(), pos_integer()) :: [binary()]
  def packets(frame, max_packet_size) when byte_size(frame) <= max_packet_size, do: [frame]

  def packets(frame, max_packet_size) when max_packet_size > 0 do
    <<packet::binary-size(max_packet_size), rest::binary>> = frame
    [packet | packets(rest, max_packet_size)]
  end

  @doc """
  Deframes and decodes a frame back into raw message bytes.

  The leading `0x01` and trailing `0x02` are optional.

      iex> ExSPIKE.Frame.unpack(<<0x00, 0x00, 0x02>>)
      {:ok, <<0x00>>}
  """
  @spec unpack(binary()) :: {:ok, binary()} | {:error, :invalid_cobs}
  def unpack(<<@high_priority, frame::binary>>), do: unpack(frame)

  def unpack(frame) when is_binary(frame) do
    size = byte_size(frame) - 1

    body =
      case frame do
        <<body::binary-size(size), @end_of_frame>> -> body
        body -> body
      end

    body |> xor() |> ExSPIKE.COBS.decode()
  end

  @doc """
  Splits a byte stream into complete frames.

  Returns `{frames, rest}`. Frames are listed in the order they completed and
  can be passed to `unpack/1`. `rest` holds the bytes of incomplete frames and
  should be prepended to the next bytes received.

  High-priority frames (starting with `0x01`) may interrupt a low-priority
  frame, as described in
  [Deframing and unescaping](https://lego.github.io/spike-prime-docs/encoding.html#deframing-and-unescaping).

      iex> ExSPIKE.Frame.split(<<0x00, 0x00, 0x02, 0x04, 0x05>>)
      {[<<0x00, 0x00, 0x02>>], <<0x04, 0x05>>}

      iex> ExSPIKE.Frame.split(<<0x10, 0x01, 0x20, 0x02, 0x11, 0x02>>)
      {[<<0x20, 0x02>>, <<0x10, 0x11, 0x02>>], <<>>}
  """
  @spec split(binary()) :: {[binary()], binary()}
  def split(stream) when is_binary(stream), do: split(stream, <<>>, nil, [])

  # `low` buffers the low-priority frame, `high` the high-priority frame
  # (nil when no high-priority frame is in progress).
  defp split(<<@high_priority, rest::binary>>, low, nil, frames),
    do: split(rest, low, <<>>, frames)

  # 0x01 during a high-priority frame is a sync error: clear queues.
  defp split(<<@high_priority, rest::binary>>, _low, _high, frames),
    do: split(rest, <<>>, <<>>, frames)

  defp split(<<@end_of_frame, rest::binary>>, low, nil, frames),
    do: split(rest, <<>>, nil, add_frame(frames, low))

  defp split(<<@end_of_frame, rest::binary>>, low, high, frames),
    do: split(rest, low, nil, add_frame(frames, high))

  defp split(<<byte, rest::binary>>, low, nil, frames),
    do: split(rest, <<low::binary, byte>>, nil, frames)

  defp split(<<byte, rest::binary>>, low, high, frames),
    do: split(rest, low, <<high::binary, byte>>, frames)

  defp split(<<>>, low, nil, frames), do: {Enum.reverse(frames), low}

  defp split(<<>>, low, high, frames),
    do: {Enum.reverse(frames), <<low::binary, @high_priority, high::binary>>}

  defp add_frame(frames, <<>>), do: frames
  defp add_frame(frames, body), do: [<<body::binary, @end_of_frame>> | frames]

  defp xor(data), do: for(<<byte <- data>>, into: <<>>, do: <<bxor(byte, @xor)>>)
end
