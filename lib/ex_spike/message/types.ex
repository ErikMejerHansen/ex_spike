# Structs for every message in https://lego.github.io/spike-prime-docs/messages.html
#
# Encoding and decoding lives in ExSPIKE.Message; these modules only describe
# the shape of each message.

defmodule ExSPIKE.Message.InfoRequest do
  @moduledoc "Asks the hub for its capabilities. Send first after connecting. (`0x00`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExSPIKE.Message.InfoResponse do
  @moduledoc "The hub's versions and protocol limits. (`0x01`)"
  defstruct [
    :rpc_major,
    :rpc_minor,
    :rpc_build,
    :firmware_major,
    :firmware_minor,
    :firmware_build,
    :max_packet_size,
    :max_message_size,
    :max_chunk_size,
    product_group_device: :spike_prime
  ]

  @type t :: %__MODULE__{
          rpc_major: 0..0xFF,
          rpc_minor: 0..0xFF,
          rpc_build: 0..0xFFFF,
          firmware_major: 0..0xFF,
          firmware_minor: 0..0xFF,
          firmware_build: 0..0xFFFF,
          max_packet_size: 0..0xFFFF,
          max_message_size: 0..0xFFFF,
          max_chunk_size: 0..0xFFFF,
          product_group_device: atom() | 0..0xFFFF
        }
end

defmodule ExSPIKE.Message.StartFirmwareUploadRequest do
  @moduledoc "Starts (or resumes) a firmware upload. `file_sha` is 20 bytes. (`0x0A`)"
  defstruct [:file_sha, :crc]
  @type t :: %__MODULE__{file_sha: <<_::160>>, crc: 0..0xFFFFFFFF}
end

defmodule ExSPIKE.Message.StartFirmwareUploadResponse do
  @moduledoc "Reply to `StartFirmwareUploadRequest`, with bytes already uploaded. (`0x0B`)"
  defstruct [:status, bytes_uploaded: 0]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status(), bytes_uploaded: 0..0xFFFFFFFF}
end

defmodule ExSPIKE.Message.StartFileUploadRequest do
  @moduledoc "Starts uploading a file to a program slot. Name is max 31 bytes. (`0x0C`)"
  defstruct [:file_name, :slot, :crc]
  @type t :: %__MODULE__{file_name: String.t(), slot: 0..0xFF, crc: 0..0xFFFFFFFF}
end

defmodule ExSPIKE.Message.StartFileUploadResponse do
  @moduledoc "Reply to `StartFileUploadRequest`. (`0x0D`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.TransferChunkRequest do
  @moduledoc "One chunk of a file or firmware transfer, with the running CRC. (`0x10`)"
  defstruct [:running_crc, :payload]
  @type t :: %__MODULE__{running_crc: 0..0xFFFFFFFF, payload: binary()}
end

defmodule ExSPIKE.Message.TransferChunkResponse do
  @moduledoc "Reply to `TransferChunkRequest`. (`0x11`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.BeginFirmwareUpdateRequest do
  @moduledoc "Installs an uploaded firmware. `file_sha` is 20 bytes. (`0x14`)"
  defstruct [:file_sha, :crc]
  @type t :: %__MODULE__{file_sha: <<_::160>>, crc: 0..0xFFFFFFFF}
end

defmodule ExSPIKE.Message.BeginFirmwareUpdateResponse do
  @moduledoc "Reply to `BeginFirmwareUpdateRequest`. (`0x15`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.SetHubNameRequest do
  @moduledoc "Renames the hub. Name is max 29 bytes. (`0x16`)"
  defstruct [:name]
  @type t :: %__MODULE__{name: String.t()}
end

defmodule ExSPIKE.Message.SetHubNameResponse do
  @moduledoc "Reply to `SetHubNameRequest`. (`0x17`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.GetHubNameRequest do
  @moduledoc "Asks for the hub's name. (`0x18`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExSPIKE.Message.GetHubNameResponse do
  @moduledoc "The hub's name. (`0x19`)"
  defstruct [:name]
  @type t :: %__MODULE__{name: String.t()}
end

defmodule ExSPIKE.Message.DeviceUuidRequest do
  @moduledoc "Asks for the hub's UUID. (`0x1A`)"
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule ExSPIKE.Message.DeviceUuidResponse do
  @moduledoc "The hub's UUID as 16 raw bytes. (`0x1B`)"
  defstruct [:uuid]
  @type t :: %__MODULE__{uuid: <<_::128>>}
end

defmodule ExSPIKE.Message.ProgramFlowRequest do
  @moduledoc "Starts or stops the program in a slot. (`0x1E`)"
  defstruct [:action, :slot]
  @type t :: %__MODULE__{action: ExSPIKE.Message.program_action(), slot: 0..0xFF}
end

defmodule ExSPIKE.Message.ProgramFlowResponse do
  @moduledoc "Reply to `ProgramFlowRequest`. (`0x1F`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.ProgramFlowNotification do
  @moduledoc "Sent by the hub when a program starts or stops. (`0x20`)"
  defstruct [:action]
  @type t :: %__MODULE__{action: ExSPIKE.Message.program_action()}
end

defmodule ExSPIKE.Message.ConsoleNotification do
  @moduledoc "Text printed by the running program. (`0x21`)"
  defstruct [:text]
  @type t :: %__MODULE__{text: String.t()}
end

defmodule ExSPIKE.Message.DeviceNotificationRequest do
  @moduledoc "Sets the device notification interval in ms. `0` disables. (`0x28`)"
  defstruct [:interval_ms]
  @type t :: %__MODULE__{interval_ms: 0..0xFFFF}
end

defmodule ExSPIKE.Message.DeviceNotificationResponse do
  @moduledoc "Reply to `DeviceNotificationRequest`. (`0x29`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end

defmodule ExSPIKE.Message.TunnelMessage do
  @moduledoc "Arbitrary payload exchanged with the running program. (`0x32`)"
  defstruct [:payload]
  @type t :: %__MODULE__{payload: binary()}
end

defmodule ExSPIKE.Message.DeviceNotification do
  @moduledoc """
  Periodic sensor and motor state. (`0x3C`)

  `messages` is a list of `ExSPIKE.Device` structs.
  """
  defstruct messages: []
  @type t :: %__MODULE__{messages: [ExSPIKE.Device.t()]}
end

defmodule ExSPIKE.Message.ClearSlotRequest do
  @moduledoc "Deletes the program in a slot. (`0x46`)"
  defstruct [:slot]
  @type t :: %__MODULE__{slot: 0..0xFF}
end

defmodule ExSPIKE.Message.ClearSlotResponse do
  @moduledoc "Reply to `ClearSlotRequest`. (`0x47`)"
  defstruct [:status]
  @type t :: %__MODULE__{status: ExSPIKE.Message.status()}
end
