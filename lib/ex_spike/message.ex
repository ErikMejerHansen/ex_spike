defmodule ExSPIKE.Message do
  @moduledoc """
  Converts message structs to and from their raw (unframed) bytes.

  Every message in the
  [SPIKE™ Prime protocol](https://lego.github.io/spike-prime-docs/messages.html)
  has a struct under `ExSPIKE.Message.*`. Encoding and decoding works in
  both directions for all of them, so the library can also be used to
  simulate a hub.

  Use `ExSPIKE.encode/2` and `ExSPIKE.decode/1` to include framing.

      iex> ExSPIKE.Message.encode(%ExSPIKE.Message.ProgramFlowRequest{action: :start, slot: 3})
      <<0x1E, 0x00, 0x03>>

      iex> ExSPIKE.Message.decode(<<0x1E, 0x00, 0x03>>)
      {:ok, %ExSPIKE.Message.ProgramFlowRequest{action: :start, slot: 3}}
  """

  alias ExSPIKE.{Device, Enums}

  alias ExSPIKE.Message.{
    BeginFirmwareUpdateRequest,
    BeginFirmwareUpdateResponse,
    ClearSlotRequest,
    ClearSlotResponse,
    ConsoleNotification,
    DeviceNotification,
    DeviceNotificationRequest,
    DeviceNotificationResponse,
    DeviceUuidRequest,
    DeviceUuidResponse,
    GetHubNameRequest,
    GetHubNameResponse,
    InfoRequest,
    InfoResponse,
    ProgramFlowNotification,
    ProgramFlowRequest,
    ProgramFlowResponse,
    SetHubNameRequest,
    SetHubNameResponse,
    StartFileUploadRequest,
    StartFileUploadResponse,
    StartFirmwareUploadRequest,
    StartFirmwareUploadResponse,
    TransferChunkRequest,
    TransferChunkResponse,
    TunnelMessage
  }

  @messages %{
    0x00 => InfoRequest,
    0x01 => InfoResponse,
    0x0A => StartFirmwareUploadRequest,
    0x0B => StartFirmwareUploadResponse,
    0x0C => StartFileUploadRequest,
    0x0D => StartFileUploadResponse,
    0x10 => TransferChunkRequest,
    0x11 => TransferChunkResponse,
    0x14 => BeginFirmwareUpdateRequest,
    0x15 => BeginFirmwareUpdateResponse,
    0x16 => SetHubNameRequest,
    0x17 => SetHubNameResponse,
    0x18 => GetHubNameRequest,
    0x19 => GetHubNameResponse,
    0x1A => DeviceUuidRequest,
    0x1B => DeviceUuidResponse,
    0x1E => ProgramFlowRequest,
    0x1F => ProgramFlowResponse,
    0x20 => ProgramFlowNotification,
    0x21 => ConsoleNotification,
    0x28 => DeviceNotificationRequest,
    0x29 => DeviceNotificationResponse,
    0x32 => TunnelMessage,
    0x3C => DeviceNotification,
    0x46 => ClearSlotRequest,
    0x47 => ClearSlotResponse
  }

  # Messages without fields.
  @empty_messages [InfoRequest, GetHubNameRequest, DeviceUuidRequest]

  # Messages whose only field is a response status.
  @status_messages [
    StartFileUploadResponse,
    TransferChunkResponse,
    BeginFirmwareUpdateResponse,
    SetHubNameResponse,
    ProgramFlowResponse,
    DeviceNotificationResponse,
    ClearSlotResponse
  ]

  @type status :: :acknowledged | :not_acknowledged | 0..0xFF
  @type program_action :: :start | :stop | 0..0xFF
  @type t :: struct()
  @type decode_error ::
          :empty | {:unknown_message, 0..0xFF} | {:malformed, module()}

  @doc """
  Returns the message type id of a message struct or module.

      iex> ExSPIKE.Message.id(ExSPIKE.Message.InfoRequest)
      0
  """
  @spec id(t() | module()) :: 0..0xFF
  def id(%module{}), do: id(module)

  for {id, module} <- @messages do
    def id(unquote(module)), do: unquote(id)
  end

  @doc """
  Encodes a message struct to raw bytes.

  Raises `ArgumentError` if a field does not fit the protocol, e.g. a name
  that is too long.
  """
  @spec encode(t()) :: binary()
  def encode(message)

  for module <- @empty_messages do
    def encode(%unquote(module){}), do: <<id(unquote(module))>>
  end

  for module <- @status_messages do
    def encode(%unquote(module){status: status}),
      do: <<id(unquote(module)), Enums.to_value(:response_status, status)>>
  end

  def encode(%InfoResponse{} = m) do
    <<0x01, m.rpc_major, m.rpc_minor, m.rpc_build::little-16, m.firmware_major, m.firmware_minor,
      m.firmware_build::little-16, m.max_packet_size::little-16, m.max_message_size::little-16,
      m.max_chunk_size::little-16,
      Enums.to_value(:product_group_device, m.product_group_device)::little-16>>
  end

  def encode(%StartFirmwareUploadRequest{file_sha: <<sha::binary-size(20)>>, crc: crc}),
    do: <<0x0A, sha::binary, crc::little-32>>

  def encode(%StartFirmwareUploadResponse{status: status, bytes_uploaded: bytes}),
    do: <<0x0B, Enums.to_value(:response_status, status), bytes::little-32>>

  def encode(%StartFileUploadRequest{file_name: name, slot: slot, crc: crc}),
    do: <<0x0C, string(name, 32)::binary, slot, crc::little-32>>

  def encode(%TransferChunkRequest{running_crc: crc, payload: payload}),
    do: <<0x10, crc::little-32, byte_size(payload)::little-16, payload::binary>>

  def encode(%BeginFirmwareUpdateRequest{file_sha: <<sha::binary-size(20)>>, crc: crc}),
    do: <<0x14, sha::binary, crc::little-32>>

  def encode(%SetHubNameRequest{name: name}), do: <<0x16, string(name, 30)::binary>>

  def encode(%GetHubNameResponse{name: name}), do: <<0x19, string(name, 30)::binary>>

  def encode(%DeviceUuidResponse{uuid: <<uuid::binary-size(16)>>}), do: <<0x1B, uuid::binary>>

  def encode(%ProgramFlowRequest{action: action, slot: slot}),
    do: <<0x1E, Enums.to_value(:program_action, action), slot>>

  def encode(%ProgramFlowNotification{action: action}),
    do: <<0x20, Enums.to_value(:program_action, action)>>

  def encode(%ConsoleNotification{text: text}), do: <<0x21, string(text, 256)::binary>>

  def encode(%DeviceNotificationRequest{interval_ms: interval}),
    do: <<0x28, interval::little-16>>

  def encode(%TunnelMessage{payload: payload}),
    do: <<0x32, byte_size(payload)::little-16, payload::binary>>

  def encode(%DeviceNotification{messages: messages}) do
    payload = Device.encode(messages)
    <<0x3C, byte_size(payload)::little-16, payload::binary>>
  end

  def encode(%ClearSlotRequest{slot: slot}), do: <<0x46, slot>>

  @doc """
  Decodes raw bytes into a message struct.

      iex> ExSPIKE.Message.decode(<<0x17, 0x00>>)
      {:ok, %ExSPIKE.Message.SetHubNameResponse{status: :acknowledged}}

      iex> ExSPIKE.Message.decode(<<0xEE>>)
      {:error, {:unknown_message, 0xEE}}

      iex> ExSPIKE.Message.decode(<<0x1E, 0x00>>)
      {:error, {:malformed, ExSPIKE.Message.ProgramFlowRequest}}
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, decode_error()}
  def decode(<<>>), do: {:error, :empty}

  def decode(<<id, body::binary>>) do
    case @messages do
      %{^id => module} ->
        case decode(module, body) do
          {:ok, message} -> {:ok, message}
          :error -> {:error, {:malformed, module}}
        end

      _ ->
        {:error, {:unknown_message, id}}
    end
  end

  for module <- @empty_messages do
    defp decode(unquote(module), <<>>), do: {:ok, %unquote(module){}}
  end

  for module <- @status_messages do
    defp decode(unquote(module), <<status>>),
      do: {:ok, %unquote(module){status: Enums.to_name(:response_status, status)}}
  end

  defp decode(
         InfoResponse,
         <<rpc_major, rpc_minor, rpc_build::little-16, fw_major, fw_minor, fw_build::little-16,
           max_packet::little-16, max_message::little-16, max_chunk::little-16,
           product::little-16>>
       ) do
    {:ok,
     %InfoResponse{
       rpc_major: rpc_major,
       rpc_minor: rpc_minor,
       rpc_build: rpc_build,
       firmware_major: fw_major,
       firmware_minor: fw_minor,
       firmware_build: fw_build,
       max_packet_size: max_packet,
       max_message_size: max_message,
       max_chunk_size: max_chunk,
       product_group_device: Enums.to_name(:product_group_device, product)
     }}
  end

  defp decode(StartFirmwareUploadRequest, <<sha::binary-size(20), crc::little-32>>),
    do: {:ok, %StartFirmwareUploadRequest{file_sha: sha, crc: crc}}

  defp decode(StartFirmwareUploadResponse, <<status, bytes::little-32>>) do
    {:ok,
     %StartFirmwareUploadResponse{
       status: Enums.to_name(:response_status, status),
       bytes_uploaded: bytes
     }}
  end

  defp decode(StartFileUploadRequest, body) do
    with [name, <<slot, crc::little-32>>] <- :binary.split(body, <<0>>) do
      {:ok, %StartFileUploadRequest{file_name: name, slot: slot, crc: crc}}
    else
      _ -> :error
    end
  end

  defp decode(TransferChunkRequest, <<crc::little-32, size::little-16, payload::binary>>)
       when byte_size(payload) == size,
       do: {:ok, %TransferChunkRequest{running_crc: crc, payload: payload}}

  defp decode(BeginFirmwareUpdateRequest, <<sha::binary-size(20), crc::little-32>>),
    do: {:ok, %BeginFirmwareUpdateRequest{file_sha: sha, crc: crc}}

  defp decode(SetHubNameRequest, body), do: {:ok, %SetHubNameRequest{name: string(body)}}

  defp decode(GetHubNameResponse, body), do: {:ok, %GetHubNameResponse{name: string(body)}}

  defp decode(DeviceUuidResponse, <<uuid::binary-size(16)>>),
    do: {:ok, %DeviceUuidResponse{uuid: uuid}}

  defp decode(ProgramFlowRequest, <<action, slot>>),
    do: {:ok, %ProgramFlowRequest{action: Enums.to_name(:program_action, action), slot: slot}}

  defp decode(ProgramFlowNotification, <<action>>),
    do: {:ok, %ProgramFlowNotification{action: Enums.to_name(:program_action, action)}}

  defp decode(ConsoleNotification, body), do: {:ok, %ConsoleNotification{text: string(body)}}

  defp decode(DeviceNotificationRequest, <<interval::little-16>>),
    do: {:ok, %DeviceNotificationRequest{interval_ms: interval}}

  defp decode(TunnelMessage, <<size::little-16, payload::binary>>)
       when byte_size(payload) == size,
       do: {:ok, %TunnelMessage{payload: payload}}

  defp decode(DeviceNotification, <<size::little-16, payload::binary>>)
       when byte_size(payload) == size,
       do: {:ok, %DeviceNotification{messages: Device.decode(payload)}}

  defp decode(ClearSlotRequest, <<slot>>), do: {:ok, %ClearSlotRequest{slot: slot}}

  defp decode(_module, _body), do: :error

  # Null-terminated string of at most `max` bytes including the terminator.
  defp string(value, max) when is_binary(value) do
    if byte_size(value) < max do
      <<value::binary, 0>>
    else
      raise ArgumentError,
            "string must be at most #{max - 1} bytes, got #{byte_size(value)}: #{inspect(value)}"
    end
  end

  defp string(body) do
    [value | _] = :binary.split(body, <<0>>)
    value
  end
end
