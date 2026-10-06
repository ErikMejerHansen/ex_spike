defmodule ExSPIKETest do
  use ExUnit.Case, async: true

  alias ExSPIKE.{Device, Message, Messages}

  describe "Given a client talking to a hub" do
    @describetag spec: ["ARCH-6", "ARCH-8"]

    test "when it sends an InfoRequest, then the hub can decode it" do
      frame = ExSPIKE.encode(Messages.info_request())

      assert ExSPIKE.decode(frame) == {:ok, %Message.InfoRequest{}}
    end

    test "when the hub replies with an InfoResponse, then the client can decode it" do
      response = %Message.InfoResponse{
        rpc_major: 1,
        rpc_minor: 0,
        rpc_build: 1,
        firmware_major: 1,
        firmware_minor: 6,
        firmware_build: 50,
        max_packet_size: 20,
        max_message_size: 1000,
        max_chunk_size: 444,
        product_group_device: :spike_prime
      }

      assert response |> ExSPIKE.encode() |> ExSPIKE.decode() == {:ok, response}
    end

    test "when a message is sent with high priority, then it still decodes" do
      frame = ExSPIKE.encode(Messages.stop_program(0), priority: :high)

      assert ExSPIKE.decode(frame) == {:ok, Messages.stop_program(0)}
    end
  end

  describe "Given a message written as a raw bitstring" do
    @describetag spec: "ARCH-7"

    test "when encoded, then it produces the same frame as the struct" do
      assert ExSPIKE.encode(<<0x1E, 0x00, 0x05>>) == ExSPIKE.encode(Messages.start_program(5))
    end

    test "when decoded into a struct, then the fields are filled in" do
      assert Message.decode(<<0x28, 0x64, 0x00>>) ==
               {:ok, %Message.DeviceNotificationRequest{interval_ms: 100}}
    end
  end

  describe "Given BLE notifications that split and join frames arbitrarily" do
    @describetag spec: ["ARCH-5", "ARCH-8"]

    setup do
      messages = [
        %Message.ConsoleNotification{text: "Hello from the hub"},
        %Message.DeviceNotification{
          messages: [
            %Device.Battery{level: 99},
            %Device.Motor{
              port: :a,
              device_type: :medium_motor,
              absolute_position: 90,
              power: 5000,
              speed: 50,
              position: 720
            }
          ]
        },
        %Message.ProgramFlowNotification{action: :stop}
      ]

      stream = messages |> Enum.map(&ExSPIKE.encode/1) |> IO.iodata_to_binary()
      %{messages: messages, stream: stream}
    end

    test "when received all at once, then every message is decoded",
         %{messages: messages, stream: stream} do
      assert ExSPIKE.decode_stream(stream) == {Enum.map(messages, &{:ok, &1}), <<>>}
    end

    test "when received in 20 byte packets, then every message is decoded",
         %{messages: messages, stream: stream} do
      {decoded, rest} =
        stream
        |> ExSPIKE.Frame.packets(20)
        |> Enum.reduce({[], <<>>}, fn packet, {decoded, rest} ->
          {new, rest} = ExSPIKE.decode_stream(rest <> packet)
          {decoded ++ new, rest}
        end)

      assert decoded == Enum.map(messages, &{:ok, &1})
      assert rest == <<>>
    end
  end

  describe "Given a corrupted frame" do
    @describetag spec: "ARCH-8"

    test "when decoded, then an error is returned" do
      assert {:error, _} = ExSPIKE.decode(<<0x01, 0x01, 0x02>>)
    end
  end

  describe "Given the project documentation" do
    @describetag spec: "DOC-2"

    test "when read, then it states there is no affiliation with The LEGO Group" do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(ExSPIKE)

      for doc <- [moduledoc, File.read!("README.md")] do
        assert doc =~ "not affiliated with"
        assert doc =~ "The LEGO Group"
      end
    end
  end
end
