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

## Livebook

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2FErikMejerHansen%2Fex_spike%2Fblob%2Fmain%2Fnotebooks%2Fspike_prime.livemd)

[notebooks/spike_prime.livemd](notebooks/spike_prime.livemd) connects to a
hub over Web Bluetooth with
[KinoWebBluetooth](https://github.com/ErikMejerHansen/kino_web_bluetooth),
asks it for its info, shows its console output and sensor readings, and
uploads and runs a program.

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
mix spec      # tests, plus writes spec/STATUS.md
mix docs      # generate documentation
```

### Spec

The requirements are in [spec/ex_spike.spec.md](https://github.com/ErikMejerHansen/ex_spike/blob/main/spec/ex_spike.spec.md),
each with an ID such as `ARCH-4`. Tests declare the requirements they
verify with a tag:

```elixir
@tag spec: "ARCH-4"
test "when the application starts, then it starts no processes" do
```

Requirements that tests can't fully cover are reviewed by hand and
recorded in [spec/reviews.exs](https://github.com/ErikMejerHansen/ex_spike/blob/main/spec/reviews.exs).

`mix spec` runs the tests and writes [spec/STATUS.md](https://github.com/ErikMejerHansen/ex_spike/blob/main/spec/STATUS.md),
which lists each requirement as tested, reviewed, failing or open.
Commit it together with spec and code changes. CI fails when it is out
of date.

### Releasing

Publishing to Hex is started by hand:

1. Bump `@version` in `mix.exs` and merge it to `main`.
2. In GitHub, open **Actions → Publish to Hex → Run workflow**. Leave
   **Dry run** ticked to build and check the package and docs first.
3. Run it again with **Dry run** unticked to publish. The workflow runs
   the tests, publishes to Hex and tags the commit as `v<version>`.

It needs a Hex API key (`mix hex.user key generate`) stored as the
`HEX_API_KEY` secret of the `hex` environment, under **Settings →
Environments**. Add required reviewers to that environment to require an
approval before each publish.

## License

MIT, see [LICENSE](https://github.com/ErikMejerHansen/ex_spike/blob/main/LICENSE).
