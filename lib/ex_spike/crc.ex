defmodule ExSPIKE.CRC do
  @moduledoc """
  CRC32 as used by the SPIKE™ Prime file transfer messages.

  Data is zero-padded to a multiple of 4 bytes before the checksum is
  calculated. Pass the previous result as `seed` to compute a running CRC.
  """

  @doc """
  Calculates the CRC32 of `data`, optionally continuing from `seed`.

      iex> ExSPIKE.CRC.crc32("abcd")
      3984772369

      iex> ExSPIKE.CRC.crc32("ab") == ExSPIKE.CRC.crc32(<<"ab", 0, 0>>)
      true

      iex> ExSPIKE.CRC.crc32("efgh", ExSPIKE.CRC.crc32("abcd")) == ExSPIKE.CRC.crc32("abcdefgh")
      true
  """
  @spec crc32(binary(), non_neg_integer()) :: non_neg_integer()
  def crc32(data, seed \\ 0) when is_binary(data) do
    padding = rem(4 - rem(byte_size(data), 4), 4)
    :erlang.crc32(seed, <<data::binary, 0::size(padding * 8)>>)
  end
end
