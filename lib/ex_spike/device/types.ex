# Structs for the device messages carried inside a DeviceNotification.
# See https://lego.github.io/spike-prime-docs/messages.html#devicenotification
#
# Encoding and decoding lives in ExSPIKE.Device.

defmodule ExSPIKE.Device.Battery do
  @moduledoc "Battery level in percent. (`0x00`)"
  defstruct [:level]
  @type t :: %__MODULE__{level: 0..100}
end

defmodule ExSPIKE.Device.ImuValues do
  @moduledoc "Orientation, accelerometer and gyroscope readings. (`0x01`)"
  defstruct [
    :up_face,
    :yaw_face,
    :yaw,
    :pitch,
    :roll,
    :accelerometer_x,
    :accelerometer_y,
    :accelerometer_z,
    :gyroscope_x,
    :gyroscope_y,
    :gyroscope_z
  ]

  @type t :: %__MODULE__{
          up_face: atom() | 0..0xFF,
          yaw_face: atom() | 0..0xFF,
          yaw: integer(),
          pitch: integer(),
          roll: integer(),
          accelerometer_x: integer(),
          accelerometer_y: integer(),
          accelerometer_z: integer(),
          gyroscope_x: integer(),
          gyroscope_y: integer(),
          gyroscope_z: integer()
        }
end

defmodule ExSPIKE.Device.MatrixDisplay5x5 do
  @moduledoc "The 25 pixel values of the hub's light matrix, row by row. (`0x02`)"
  defstruct [:pixels]
  @type t :: %__MODULE__{pixels: [0..0xFF]}
end

defmodule ExSPIKE.Device.Motor do
  @moduledoc "State of a motor. (`0x0A`)"
  defstruct [:port, :device_type, :absolute_position, :power, :speed, :position]

  @type t :: %__MODULE__{
          port: atom() | 0..0xFF,
          device_type: atom() | 0..0xFF,
          absolute_position: -180..179,
          power: -10_000..10_000,
          speed: -100..100,
          position: integer()
        }
end

defmodule ExSPIKE.Device.ForceSensor do
  @moduledoc "State of a force sensor. `value` is 0-100. (`0x0B`)"
  defstruct [:port, :value, :pressed]
  @type t :: %__MODULE__{port: atom() | 0..0xFF, value: 0..100, pressed: boolean()}
end

defmodule ExSPIKE.Device.ColorSensor do
  @moduledoc "State of a color sensor. Raw RGB values are 0-1023. (`0x0C`)"
  defstruct [:port, :color, :red, :green, :blue]

  @type t :: %__MODULE__{
          port: atom() | 0..0xFF,
          color: atom() | 0..0xFF,
          red: 0..1023,
          green: 0..1023,
          blue: 0..1023
        }
end

defmodule ExSPIKE.Device.DistanceSensor do
  @moduledoc "Distance in mm (40-2000), or `-1` if nothing is detected. (`0x0D`)"
  defstruct [:port, :distance]
  @type t :: %__MODULE__{port: atom() | 0..0xFF, distance: integer()}
end

defmodule ExSPIKE.Device.ColorMatrix3x3 do
  @moduledoc """
  The 9 pixels of a 3x3 color light matrix. (`0x0E`)

  Each pixel byte holds the brightness in the high nibble and the color in
  the low nibble.
  """
  defstruct [:port, :pixels]
  @type t :: %__MODULE__{port: atom() | 0..0xFF, pixels: [0..0xFF]}
end

defmodule ExSPIKE.Device.Unknown do
  @moduledoc """
  A device message this library does not know.

  Since device messages have no length prefix, `data` holds every remaining
  byte of the notification payload, starting after `id`.
  """
  defstruct [:id, :data]
  @type t :: %__MODULE__{id: 0..0xFF, data: binary()}
end
