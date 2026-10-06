# ExSPIKE

Stateless encoder and decoder for the LEGO® SPIKE™ Prime BLE protocol, written
in Elixir and based on the
[official protocol documentation](https://lego.github.io/spike-prime-docs/).

> [!IMPORTANT]
> ExSPIKE is an independent project. It is **not affiliated with**, sponsored,
> authorized or endorsed by The LEGO Group. LEGO® and SPIKE™ are trademarks of
> The LEGO Group.

ExSPIKE turns messages into bytes and bytes into messages. It holds no state
and starts no processes: you bring the BLE connection.

## Installation

```elixir
def deps do
  [{:ex_spike, "~> 0.1.0"}]
end
```

## Usage

### Sending messages

Build a message and encode it into a frame ready to write to the hub's RX
characteristic:

```elixir
frame = ExSPIKE.Messages.info_request() |> ExSPIKE.encode()
#=> <<0, 0, 2>>

# Messages can also be written as raw bitstrings:
frame = ExSPIKE.encode(<<0x1E, 0x00, 0x05>>)   # start program in slot 5
```

If a frame is larger than the hub's `max_packet_size`, split it:

```elixir
ExSPIKE.Frame.packets(frame, info.max_packet_size)
```

### Receiving messages

BLE notifications can hold part of a frame, or several frames. Pass the bytes
to `decode_stream/1` and keep the `rest` for the next notification:

```elixir
{results, rest} = ExSPIKE.decode_stream(rest <> notification)

for {:ok, message} <- results do
  case message do
    %ExSPIKE.Message.ConsoleNotification{text: text} -> IO.puts(text)
    %ExSPIKE.Message.DeviceNotification{messages: devices} -> IO.inspect(devices)
    _ -> :ok
  end
end
```

A single complete frame can be decoded with `ExSPIKE.decode/1`, and raw message
bytes with `ExSPIKE.Message.decode/1`.

### Uploading and running a program

```elixir
program = "print('Hello from Elixir')"

[
  ExSPIKE.Messages.clear_slot(0),
  ExSPIKE.Messages.start_file_upload("program.py", 0, ExSPIKE.CRC.crc32(program))
  | ExSPIKE.Messages.transfer_chunks(program, info.max_chunk_size)
] ++ [ExSPIKE.Messages.start_program(0)]
|> Enum.map(&ExSPIKE.encode/1)
```

Send each frame and wait for the hub's response before sending the next.

## Modules

| Module             | Purpose                                                 |
| ------------------ | ------------------------------------------------------- |
| `ExSPIKE`          | Encode/decode messages to/from frames                   |
| `ExSPIKE.Messages` | Functions that build the messages a client sends        |
| `ExSPIKE.Message`  | Message structs to/from raw bytes                       |
| `ExSPIKE.Device`   | Device messages inside a `DeviceNotification`           |
| `ExSPIKE.Frame`    | Framing: COBS, XOR, delimiters, stream splitting        |
| `ExSPIKE.CRC`      | CRC32 for file transfers                                |
| `ExSPIKE.Enums`    | Protocol enumerations as atoms                          |

## Development

```sh
mix test      # BDD style tests and doctests
mix docs      # generate documentation
```

## License

MIT, see [LICENSE](LICENSE).
