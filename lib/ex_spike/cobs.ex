defmodule ExSPIKE.COBS do
  @moduledoc """
  The SPIKE™ Prime variant of Consistent Overhead Byte Stuffing.

  Standard COBS only removes `0x00`; this variant removes `0x00`, `0x01`
  and `0x02` so they can be used as delimiters. Each block starts with a
  code word:

      code_word = block_size + 2 + delimiter * 84

  where `block_size` includes the code word itself (max 84). The code word
  `0xFF` marks a full block with no delimiter.

  See [Encoding](https://lego.github.io/spike-prime-docs/encoding.html).
  """

  @max_block 84
  @no_delimiter 0xFF
  @offset 2

  @doc """
  Encodes `data` so that the output contains no `0x00`, `0x01` or `0x02` bytes.

      iex> ExSPIKE.COBS.encode(<<0, 1, 2, 3>>)
      <<3, 87, 171, 4, 3>>
  """
  @spec encode(binary()) :: binary()
  def encode(data) when is_binary(data), do: encode(data, [], 1, [])

  # `block` holds the current block's bytes reversed, `size` counts the
  # block including its code word, `out` is the finished iodata.
  defp encode(<<byte, rest::binary>>, block, size, out) when byte > @offset do
    block = [byte | block]

    if size + 1 > @max_block do
      encode(rest, [], 1, [out, @no_delimiter | Enum.reverse(block)])
    else
      encode(rest, block, size + 1, out)
    end
  end

  defp encode(<<delimiter, rest::binary>>, block, size, out) do
    code = delimiter * @max_block + size + @offset
    encode(rest, [], 1, [out, code | Enum.reverse(block)])
  end

  defp encode(<<>>, block, size, out) do
    IO.iodata_to_binary([out, size + @offset | Enum.reverse(block)])
  end

  @doc """
  Decodes COBS encoded `data`.

      iex> ExSPIKE.COBS.decode(<<3, 87, 171, 4, 3>>)
      {:ok, <<0, 1, 2, 3>>}

      iex> ExSPIKE.COBS.decode(<<1, 2, 3>>)
      {:error, :invalid_cobs}
  """
  @spec decode(binary()) :: {:ok, binary()} | {:error, :invalid_cobs}
  def decode(<<code, rest::binary>>) when code > @offset do
    decode(rest, unescape(code), [])
  end

  def decode(_), do: {:error, :invalid_cobs}

  defp decode(data, {value, size}, out) do
    data_size = size - 1

    case data do
      <<chunk::binary-size(data_size)>> ->
        {:ok, IO.iodata_to_binary([out, chunk])}

      <<chunk::binary-size(data_size), code, rest::binary>> when code > @offset ->
        decode(rest, unescape(code), [out, chunk | List.wrap(value)])

      _ ->
        {:error, :invalid_cobs}
    end
  end

  defp unescape(@no_delimiter), do: {nil, @max_block + 1}

  defp unescape(code) do
    case {div(code - @offset, @max_block), rem(code - @offset, @max_block)} do
      {value, 0} -> {value - 1, @max_block}
      {value, size} -> {value, size}
    end
  end
end
