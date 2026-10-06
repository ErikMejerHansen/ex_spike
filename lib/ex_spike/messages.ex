defmodule ExSPIKE.Messages do
  @moduledoc """
  Functions for building the messages a client sends to the hub.

  Each function returns a message struct, ready for `ExSPIKE.encode/2`:

      iex> ExSPIKE.Messages.start_program(0) |> ExSPIKE.encode()
      <<0x07, 0x1D, 0x00, 0x00, 0x02>>

  Messages sent by the hub (responses and notifications) are just structs:
  build them with `%ExSPIKE.Message.InfoResponse{...}` if you need to.
  """

  alias ExSPIKE.CRC
  alias ExSPIKE.Message

  @doc "Asks the hub for its capabilities. Always send this first."
  @spec info_request() :: Message.InfoRequest.t()
  def info_request, do: %Message.InfoRequest{}

  @doc "Asks for the hub's name."
  @spec get_hub_name() :: Message.GetHubNameRequest.t()
  def get_hub_name, do: %Message.GetHubNameRequest{}

  @doc "Renames the hub. The name may be at most 29 bytes."
  @spec set_hub_name(String.t()) :: Message.SetHubNameRequest.t()
  def set_hub_name(name), do: %Message.SetHubNameRequest{name: name}

  @doc "Asks for the hub's UUID."
  @spec device_uuid() :: Message.DeviceUuidRequest.t()
  def device_uuid, do: %Message.DeviceUuidRequest{}

  @doc "Starts the program in `slot`."
  @spec start_program(0..0xFF) :: Message.ProgramFlowRequest.t()
  def start_program(slot), do: %Message.ProgramFlowRequest{action: :start, slot: slot}

  @doc "Stops the program in `slot`."
  @spec stop_program(0..0xFF) :: Message.ProgramFlowRequest.t()
  def stop_program(slot), do: %Message.ProgramFlowRequest{action: :stop, slot: slot}

  @doc "Deletes the program in `slot`."
  @spec clear_slot(0..0xFF) :: Message.ClearSlotRequest.t()
  def clear_slot(slot), do: %Message.ClearSlotRequest{slot: slot}

  @doc """
  Asks the hub to send device notifications every `interval_ms`.
  Pass `0` to disable them.
  """
  @spec device_notifications(0..0xFFFF) :: Message.DeviceNotificationRequest.t()
  def device_notifications(interval_ms),
    do: %Message.DeviceNotificationRequest{interval_ms: interval_ms}

  @doc "Sends an arbitrary payload to the running program."
  @spec tunnel(binary()) :: Message.TunnelMessage.t()
  def tunnel(payload), do: %Message.TunnelMessage{payload: payload}

  @doc """
  Starts a file upload. `file_name` may be at most 31 bytes.

  `crc` is the CRC32 of the whole file, see `ExSPIKE.CRC.crc32/2`.
  """
  @spec start_file_upload(String.t(), 0..0xFF, non_neg_integer()) ::
          Message.StartFileUploadRequest.t()
  def start_file_upload(file_name, slot, crc),
    do: %Message.StartFileUploadRequest{file_name: file_name, slot: slot, crc: crc}

  @doc "Builds a single transfer chunk."
  @spec transfer_chunk(non_neg_integer(), binary()) :: Message.TransferChunkRequest.t()
  def transfer_chunk(running_crc, payload),
    do: %Message.TransferChunkRequest{running_crc: running_crc, payload: payload}

  @doc """
  Splits `data` into transfer chunks of at most `max_chunk_size` bytes, each
  carrying the running CRC. Use the `max_chunk_size` from the hub's
  `ExSPIKE.Message.InfoResponse`.

      iex> ExSPIKE.Messages.transfer_chunks("abcdef", 4) |> Enum.map(& &1.payload)
      ["abcd", "ef"]
  """
  @spec transfer_chunks(binary(), pos_integer()) :: [Message.TransferChunkRequest.t()]
  def transfer_chunks(data, max_chunk_size) when max_chunk_size > 0 do
    data
    |> chunk(max_chunk_size)
    |> Enum.map_reduce(0, fn payload, crc ->
      crc = CRC.crc32(payload, crc)
      {transfer_chunk(crc, payload), crc}
    end)
    |> elem(0)
  end

  @doc "Starts (or resumes) a firmware upload. `file_sha` is 20 bytes."
  @spec start_firmware_upload(<<_::160>>, non_neg_integer()) ::
          Message.StartFirmwareUploadRequest.t()
  def start_firmware_upload(file_sha, crc),
    do: %Message.StartFirmwareUploadRequest{file_sha: file_sha, crc: crc}

  @doc "Installs an uploaded firmware. `file_sha` is 20 bytes."
  @spec begin_firmware_update(<<_::160>>, non_neg_integer()) ::
          Message.BeginFirmwareUpdateRequest.t()
  def begin_firmware_update(file_sha, crc),
    do: %Message.BeginFirmwareUpdateRequest{file_sha: file_sha, crc: crc}

  defp chunk(data, size) when byte_size(data) <= size, do: [data]

  defp chunk(data, size) do
    <<head::binary-size(size), rest::binary>> = data
    [head | chunk(rest, size)]
  end
end
