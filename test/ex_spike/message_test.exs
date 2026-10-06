defmodule ExSPIKE.MessageTest do
  use ExUnit.Case, async: true

  alias ExSPIKE.Device
  alias ExSPIKE.Message

  @sha :binary.copy(<<0xAB>>, 20)
  @uuid :binary.list_to_bin(Enum.to_list(1..16))

  # Every message in the protocol, paired with its expected raw bytes.
  @examples [
    {%Message.InfoRequest{}, <<0x00>>},
    {%Message.InfoResponse{
       rpc_major: 1,
       rpc_minor: 2,
       rpc_build: 0x0304,
       firmware_major: 5,
       firmware_minor: 6,
       firmware_build: 0x0708,
       max_packet_size: 20,
       max_message_size: 512,
       max_chunk_size: 444,
       product_group_device: :spike_prime
     }, <<0x01, 1, 2, 0x04, 0x03, 5, 6, 0x08, 0x07, 20, 0, 0x00, 0x02, 0xBC, 0x01, 0x00, 0x00>>},
    {%Message.StartFirmwareUploadRequest{file_sha: @sha, crc: 0x11223344},
     <<0x0A, @sha::binary, 0x44, 0x33, 0x22, 0x11>>},
    {%Message.StartFirmwareUploadResponse{status: :acknowledged, bytes_uploaded: 256},
     <<0x0B, 0x00, 0x00, 0x01, 0x00, 0x00>>},
    {%Message.StartFileUploadRequest{file_name: "program.py", slot: 3, crc: 0x11223344},
     <<0x0C, "program.py", 0, 3, 0x44, 0x33, 0x22, 0x11>>},
    {%Message.StartFileUploadResponse{status: :acknowledged}, <<0x0D, 0x00>>},
    {%Message.TransferChunkRequest{running_crc: 0x11223344, payload: "abc"},
     <<0x10, 0x44, 0x33, 0x22, 0x11, 3, 0, "abc">>},
    {%Message.TransferChunkResponse{status: :not_acknowledged}, <<0x11, 0x01>>},
    {%Message.BeginFirmwareUpdateRequest{file_sha: @sha, crc: 0x11223344},
     <<0x14, @sha::binary, 0x44, 0x33, 0x22, 0x11>>},
    {%Message.BeginFirmwareUpdateResponse{status: :acknowledged}, <<0x15, 0x00>>},
    {%Message.SetHubNameRequest{name: "Brick"}, <<0x16, "Brick", 0>>},
    {%Message.SetHubNameResponse{status: :acknowledged}, <<0x17, 0x00>>},
    {%Message.GetHubNameRequest{}, <<0x18>>},
    {%Message.GetHubNameResponse{name: "Brick"}, <<0x19, "Brick", 0>>},
    {%Message.DeviceUuidRequest{}, <<0x1A>>},
    {%Message.DeviceUuidResponse{uuid: @uuid}, <<0x1B, @uuid::binary>>},
    {%Message.ProgramFlowRequest{action: :stop, slot: 7}, <<0x1E, 0x01, 7>>},
    {%Message.ProgramFlowResponse{status: :acknowledged}, <<0x1F, 0x00>>},
    {%Message.ProgramFlowNotification{action: :start}, <<0x20, 0x00>>},
    {%Message.ConsoleNotification{text: "hello"}, <<0x21, "hello", 0>>},
    {%Message.DeviceNotificationRequest{interval_ms: 1000}, <<0x28, 0xE8, 0x03>>},
    {%Message.DeviceNotificationResponse{status: :acknowledged}, <<0x29, 0x00>>},
    {%Message.TunnelMessage{payload: <<1, 2, 3>>}, <<0x32, 3, 0, 1, 2, 3>>},
    {%Message.DeviceNotification{messages: [%Device.Battery{level: 50}]},
     <<0x3C, 2, 0, 0x00, 50>>},
    {%Message.ClearSlotRequest{slot: 4}, <<0x46, 4>>},
    {%Message.ClearSlotResponse{status: :acknowledged}, <<0x47, 0x00>>}
  ]

  for {message, bytes} <- @examples do
    name = message.__struct__ |> Module.split() |> List.last()

    describe "Given a #{name}" do
      test "when encoded, then it produces the documented bytes" do
        assert Message.encode(unquote(Macro.escape(message))) == unquote(bytes)
      end

      test "when its bytes are decoded, then the struct is restored" do
        assert Message.decode(unquote(bytes)) == {:ok, unquote(Macro.escape(message))}
      end
    end
  end

  test "every message type in the protocol is covered" do
    covered = Enum.map(@examples, fn {message, _} -> Message.id(message) end)
    assert Enum.sort(covered) == Enum.sort(Enum.uniq(covered))
    assert length(covered) == 26
  end

  describe "Given a name that is too long" do
    test "when a SetHubNameRequest is encoded, then it raises" do
      assert_raise ArgumentError, fn ->
        Message.encode(%Message.SetHubNameRequest{name: String.duplicate("x", 30)})
      end
    end

    test "when a StartFileUploadRequest is encoded, then it raises" do
      assert_raise ArgumentError, fn ->
        Message.encode(%Message.StartFileUploadRequest{
          file_name: String.duplicate("x", 32),
          slot: 0,
          crc: 0
        })
      end
    end

    test "when the name is exactly at the limit, then it is encoded" do
      name = String.duplicate("x", 29)
      assert Message.encode(%Message.SetHubNameRequest{name: name}) == <<0x16, name::binary, 0>>
    end
  end

  describe "Given a hub name padded with null bytes" do
    test "when decoded, then the padding is dropped" do
      assert Message.decode(<<0x19, "Brick", 0, 0, 0, 0>>) ==
               {:ok, %Message.GetHubNameResponse{name: "Brick"}}
    end
  end

  describe "Given an enum value the library does not know" do
    test "when decoded, then the raw integer is kept" do
      assert Message.decode(<<0x1F, 0x07>>) == {:ok, %Message.ProgramFlowResponse{status: 0x07}}
    end

    test "when encoded as an integer, then it is passed through" do
      assert Message.encode(%Message.ProgramFlowRequest{action: 0x05, slot: 0}) ==
               <<0x1E, 0x05, 0x00>>
    end
  end

  describe "Given bytes that are not a valid message" do
    test "when empty, then decoding reports :empty" do
      assert Message.decode(<<>>) == {:error, :empty}
    end

    test "when the message type is unknown, then decoding reports it" do
      assert Message.decode(<<0xEE, 1, 2>>) == {:error, {:unknown_message, 0xEE}}
    end

    test "when a message is truncated, then decoding reports it as malformed" do
      assert Message.decode(<<0x01, 1, 2>>) == {:error, {:malformed, Message.InfoResponse}}
    end

    test "when a message has trailing bytes, then decoding reports it as malformed" do
      assert Message.decode(<<0x46, 1, 2>>) == {:error, {:malformed, Message.ClearSlotRequest}}
    end

    test "when a payload size does not match, then decoding reports it as malformed" do
      assert Message.decode(<<0x32, 5, 0, 1>>) == {:error, {:malformed, Message.TunnelMessage}}
    end
  end
end
