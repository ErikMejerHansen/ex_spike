defmodule ExSPIKE.MessagesTest do
  use ExUnit.Case, async: true

  @moduletag spec: "ARCH-6"

  alias ExSPIKE.{CRC, Message, Messages}

  describe "Given the convenience functions" do
    test "when called, then they build the matching message structs" do
      assert Messages.info_request() == %Message.InfoRequest{}
      assert Messages.get_hub_name() == %Message.GetHubNameRequest{}
      assert Messages.set_hub_name("Brick") == %Message.SetHubNameRequest{name: "Brick"}
      assert Messages.device_uuid() == %Message.DeviceUuidRequest{}
      assert Messages.start_program(1) == %Message.ProgramFlowRequest{action: :start, slot: 1}
      assert Messages.stop_program(1) == %Message.ProgramFlowRequest{action: :stop, slot: 1}
      assert Messages.clear_slot(2) == %Message.ClearSlotRequest{slot: 2}

      assert Messages.device_notifications(50) == %Message.DeviceNotificationRequest{
               interval_ms: 50
             }

      assert Messages.tunnel("hi") == %Message.TunnelMessage{payload: "hi"}

      assert Messages.start_file_upload("a.py", 0, 123) ==
               %Message.StartFileUploadRequest{file_name: "a.py", slot: 0, crc: 123}

      assert Messages.transfer_chunk(123, "abc") ==
               %Message.TransferChunkRequest{running_crc: 123, payload: "abc"}
    end

    test "when a firmware SHA is given, then the firmware messages carry it" do
      sha = :binary.copy(<<1>>, 20)

      assert Messages.start_firmware_upload(sha, 9) ==
               %Message.StartFirmwareUploadRequest{file_sha: sha, crc: 9}

      assert Messages.begin_firmware_update(sha, 9) ==
               %Message.BeginFirmwareUpdateRequest{file_sha: sha, crc: 9}
    end
  end

  describe "Given a program to upload" do
    setup do
      %{program: String.duplicate("print('hello')\n", 20)}
    end

    test "when split into chunks, then no chunk exceeds the max chunk size", %{program: program} do
      chunks = Messages.transfer_chunks(program, 64)

      assert Enum.all?(chunks, &(byte_size(&1.payload) <= 64))
      assert Enum.map_join(chunks, & &1.payload) == program
    end

    test "when split into chunks, then the last running CRC equals the file CRC",
         %{program: program} do
      chunks = Messages.transfer_chunks(program, 64)

      assert List.last(chunks).running_crc == CRC.crc32(program)
    end

    test "when split into chunks, then each running CRC continues from the previous one",
         %{program: program} do
      [first, second | _] = Messages.transfer_chunks(program, 64)

      assert first.running_crc == CRC.crc32(first.payload)
      assert second.running_crc == CRC.crc32(second.payload, first.running_crc)
    end
  end
end
