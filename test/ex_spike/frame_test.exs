defmodule ExSPIKE.FrameTest do
  use ExUnit.Case, async: true

  alias ExSPIKE.{COBS, Frame}

  # Test vectors from the official reference implementation:
  # https://github.com/LEGO/spike-prime-docs/blob/main/examples/python/_tests/test_cobs.py
  @vectors [
    {"bytes that need escaping",
     <<0, 1, 2, 3, 4, 5, 6, 0, 1, 2, 3, 4, 5, 84, 234, 54, 0, 45, 23, 12>>,
     <<0, 84, 168, 4, 0, 7, 6, 5, 84, 168, 10, 0, 7, 6, 87, 233, 53, 5, 46, 20, 15, 2>>},
    {"bytes that need no escaping", <<255, 254, 223, 213, 125, 175, 100, 97, 54, 21, 65, 45>>,
     <<12, 252, 253, 220, 214, 126, 172, 103, 98, 53, 22, 66, 46, 2>>},
    {"a long message with many escapes",
     <<10, 3, 0, 61, 91, 151, 0, 185, 217, 87, 112, 195, 221, 207, 216, 40, 63, 220, 253, 42, 248,
       85, 195, 175, 6, 126, 181, 50, 23, 174, 250, 255, 3, 183, 30, 224, 14, 2, 199, 86, 57, 227,
       0, 242, 234, 255, 194, 243, 107, 162, 105, 235, 251, 177, 77, 73, 93, 187, 122, 149, 235,
       171, 213, 7, 93, 177, 79, 179, 43, 244, 0, 49, 243, 10, 46, 211, 18, 98, 107, 69, 134, 138,
       196, 19, 134, 96, 95, 140, 54, 149, 187, 149, 27, 70, 216, 79, 117, 5, 123, 237, 249, 196,
       207, 167, 114, 54, 231, 166, 213, 205, 203, 118, 61, 224, 118, 89, 107, 44, 11, 141, 68,
       108, 23, 91, 25, 18, 71, 42, 50, 212, 151, 74, 76, 136, 150, 152, 28, 45, 145, 190, 172,
       224, 129, 163, 82, 162, 237, 181, 71, 111, 92, 154, 178, 208, 0, 101, 108, 80, 11, 173, 33,
       94, 5, 253, 183, 192, 14, 215, 22, 218, 127, 245, 41, 117, 107, 31, 117, 44>>,
     <<6, 9, 0, 5, 62, 88, 148, 202, 186, 218, 84, 115, 192, 222, 204, 219, 43, 60, 223, 254, 41,
       251, 86, 192, 172, 5, 125, 182, 49, 20, 173, 249, 252, 0, 180, 29, 227, 13, 4, 196, 85, 58,
       224, 29, 241, 233, 252, 193, 240, 104, 161, 106, 232, 248, 178, 78, 74, 94, 184, 121, 150,
       232, 168, 214, 4, 94, 178, 76, 176, 40, 247, 85, 50, 240, 9, 45, 208, 17, 97, 104, 70, 133,
       137, 199, 16, 133, 99, 92, 143, 53, 150, 184, 150, 24, 69, 219, 76, 118, 6, 120, 238, 250,
       199, 204, 164, 113, 53, 228, 165, 214, 206, 200, 117, 62, 227, 117, 90, 104, 47, 8, 142,
       71, 111, 20, 88, 26, 17, 68, 41, 49, 215, 148, 73, 79, 139, 149, 155, 31, 46, 146, 189,
       175, 227, 130, 160, 81, 161, 238, 182, 68, 108, 95, 153, 177, 211, 25, 102, 111, 83, 8,
       174, 34, 93, 6, 254, 180, 195, 13, 212, 21, 217, 124, 246, 42, 118, 104, 28, 118, 47, 2>>}
  ]

  for {name, message, frame} <- @vectors do
    describe "Given #{name} from the official test vectors" do
      test "when packed, then it matches the reference frame" do
        assert Frame.pack(unquote(message)) == unquote(frame)
      end

      test "when the reference frame is unpacked, then the message is restored" do
        assert Frame.unpack(unquote(frame)) == {:ok, unquote(message)}
      end
    end
  end

  describe "Given any message" do
    setup do
      # Every byte value, and runs long enough to cross the 84 byte block limit.
      messages =
        [<<>>, :binary.list_to_bin(Enum.to_list(0..255))] ++
          for size <- 80..260, fill <- [0, 1, 2, 3, 0xFF] do
            :binary.copy(<<fill>>, size)
          end

      %{messages: messages}
    end

    test "when packed, then the frame body contains no delimiters", %{messages: messages} do
      for message <- messages do
        frame = Frame.pack(message)
        body = binary_part(frame, 0, byte_size(frame) - 1)

        assert :binary.match(body, [<<0x01>>, <<0x02>>, <<0x03>>]) == :nomatch
      end
    end

    test "when packed and unpacked, then it is unchanged", %{messages: messages} do
      for message <- messages do
        assert message |> Frame.pack() |> Frame.unpack() == {:ok, message}
      end
    end

    test "when packed with high priority, then the frame starts with 0x01 and still unpacks" do
      frame = Frame.pack(<<0x1E, 0x00, 0x00>>, priority: :high)

      assert <<0x01, _::binary>> = frame
      assert Frame.unpack(frame) == {:ok, <<0x1E, 0x00, 0x00>>}
    end
  end

  describe "Given corrupt COBS data" do
    test "when decoded, then an error is returned instead of garbage" do
      assert COBS.decode(<<>>) == {:error, :invalid_cobs}
      assert COBS.decode(<<0x02, 0x10>>) == {:error, :invalid_cobs}
      assert COBS.decode(<<0x10, 0x20>>) == {:error, :invalid_cobs}
    end
  end

  describe "Given a byte stream from the hub" do
    test "when it holds one complete frame, then that frame is returned with no rest" do
      assert Frame.split(<<0x10, 0x20, 0x02>>) == {[<<0x10, 0x20, 0x02>>], <<>>}
    end

    test "when it holds several frames, then all are returned in order" do
      assert Frame.split(<<0x10, 0x02, 0x20, 0x02>>) == {[<<0x10, 0x02>>, <<0x20, 0x02>>], <<>>}
    end

    test "when a frame is incomplete, then its bytes are returned as rest" do
      assert Frame.split(<<0x10, 0x02, 0x20>>) == {[<<0x10, 0x02>>], <<0x20>>}
    end

    test "when the rest is prepended to the next bytes, then the frame completes" do
      {[], rest} = Frame.split(<<0x10>>)
      assert Frame.split(rest <> <<0x20, 0x02>>) == {[<<0x10, 0x20, 0x02>>], <<>>}
    end

    test "when a high-priority frame interrupts a low-priority frame, then both are returned" do
      stream = <<0x10, 0x01, 0x20, 0x02, 0x11, 0x02>>
      assert Frame.split(stream) == {[<<0x20, 0x02>>, <<0x10, 0x11, 0x02>>], <<>>}
    end

    test "when a stream is cut inside a high-priority frame, then splitting resumes correctly" do
      {[], rest} = Frame.split(<<0x10, 0x01, 0x20>>)

      assert Frame.split(rest <> <<0x02, 0x11, 0x02>>) ==
               {[<<0x20, 0x02>>, <<0x10, 0x11, 0x02>>], <<>>}
    end

    test "when 0x01 arrives during a high-priority frame, then both queues are cleared" do
      assert Frame.split(<<0x10, 0x01, 0x20, 0x01, 0x30, 0x02>>) == {[<<0x30, 0x02>>], <<>>}
    end

    test "when delimiters arrive without data, then no empty frames are returned" do
      assert Frame.split(<<0x02, 0x02, 0x01, 0x02>>) == {[], <<>>}
    end
  end

  describe "Given a frame larger than the hub's max packet size" do
    test "when split into packets, then each packet fits and together they form the frame" do
      frame = :binary.copy(<<0xAA>>, 50)
      packets = Frame.packets(frame, 20)

      assert Enum.map(packets, &byte_size/1) == [20, 20, 10]
      assert IO.iodata_to_binary(packets) == frame
    end
  end
end
