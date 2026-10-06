defmodule ExSPIKE do
  @moduledoc """
  Stateless encoder and decoder for the LEGO® SPIKE™ Prime BLE protocol, as
  documented at <https://lego.github.io/spike-prime-docs/>.

  > #### Not affiliated with LEGO {: .warning}
  >
  > ExSPIKE is an independent project. It is not affiliated with, sponsored,
  > authorized or endorsed by The LEGO Group. LEGO® and SPIKE™ are
  > trademarks of The LEGO Group.

  ExSPIKE only turns messages into bytes and bytes into messages. It holds no
  state and starts no processes; you bring the BLE connection.

  ## Encoding

  Build a message with `ExSPIKE.Messages` (or a struct from
  `ExSPIKE.Message.*`) and encode it into a frame ready to write to the hub:

      iex> ExSPIKE.Messages.info_request() |> ExSPIKE.encode()
      <<0x00, 0x00, 0x02>>

  Raw message bytes work too:

      iex> ExSPIKE.encode(<<0x00>>)
      <<0x00, 0x00, 0x02>>

  ## Decoding

      iex> ExSPIKE.decode(<<0x07, 0x23, 0x00, 0x02>>)
      {:ok, %ExSPIKE.Message.ProgramFlowNotification{action: :start}}

  BLE notifications may contain partial or multiple frames. Use
  `decode_stream/1` and keep the returned rest for the next notification:

      iex> {messages, rest} = ExSPIKE.decode_stream(<<0x00, 0x00, 0x02, 0x04>>)
      iex> messages
      [{:ok, %ExSPIKE.Message.InfoRequest{}}]
      iex> rest
      <<0x04>>

  ## Layers

    * `ExSPIKE.Messages` - functions that build messages
    * `ExSPIKE.Message` - message structs to/from raw bytes
    * `ExSPIKE.Frame` - raw bytes to/from frames (COBS, XOR and delimiters)
    * `ExSPIKE.CRC` - CRC32 for file transfers
    * `ExSPIKE.Enums` - protocol enumerations as atoms
  """

  alias ExSPIKE.{Frame, Message}

  @doc """
  Encodes a message struct, or raw message bytes, into a frame.

  ## Options

    * `:priority` - `:low` (default) or `:high`, see `ExSPIKE.Frame.pack/2`.
  """
  @spec encode(Message.t() | binary(), keyword()) :: binary()
  def encode(message, opts \\ [])
  def encode(bytes, opts) when is_binary(bytes), do: Frame.pack(bytes, opts)

  def encode(message, opts) when is_struct(message),
    do: message |> Message.encode() |> encode(opts)

  @doc """
  Decodes a single frame into a message struct.
  """
  @spec decode(binary()) :: {:ok, Message.t()} | {:error, Message.decode_error() | :invalid_cobs}
  def decode(frame) when is_binary(frame) do
    with {:ok, bytes} <- Frame.unpack(frame), do: Message.decode(bytes)
  end

  @doc """
  Decodes every complete frame in `stream`.

  Returns `{results, rest}`, where `results` holds one `decode/1` result per
  frame and `rest` holds bytes of incomplete frames. Prepend `rest` to the
  next bytes you receive.
  """
  @spec decode_stream(binary()) ::
          {[{:ok, Message.t()} | {:error, term()}], binary()}
  def decode_stream(stream) when is_binary(stream) do
    {frames, rest} = Frame.split(stream)
    {Enum.map(frames, &decode/1), rest}
  end
end
