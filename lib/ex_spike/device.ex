defmodule ExSPIKE.Device do
  @moduledoc """
  Encodes and decodes the device messages inside a
  `ExSPIKE.Message.DeviceNotification` payload.

  You rarely need this module directly: `ExSPIKE.Message` uses it when
  handling device notifications.

      iex> ExSPIKE.Device.decode(<<0x00, 87, 0x0D, 0x01, 0xE8, 0x03>>)
      [%ExSPIKE.Device.Battery{level: 87}, %ExSPIKE.Device.DistanceSensor{port: :b, distance: 1000}]
  """

  alias ExSPIKE.Device.{
    Battery,
    ColorMatrix3x3,
    ColorSensor,
    DistanceSensor,
    ForceSensor,
    ImuValues,
    MatrixDisplay5x5,
    Motor,
    Unknown
  }

  alias ExSPIKE.Enums

  @type t ::
          Battery.t()
          | ImuValues.t()
          | MatrixDisplay5x5.t()
          | Motor.t()
          | ForceSensor.t()
          | ColorSensor.t()
          | DistanceSensor.t()
          | ColorMatrix3x3.t()
          | Unknown.t()

  @doc """
  Decodes a device notification payload into a list of device messages.

  Decoding stops at the first unknown device message, which is returned as
  `ExSPIKE.Device.Unknown` holding the remaining bytes.
  """
  @spec decode(binary()) :: [t()]
  def decode(<<>>), do: []

  def decode(payload) do
    {message, rest} = decode_one(payload)
    [message | decode(rest)]
  end

  defp decode_one(<<0x00, level, rest::binary>>), do: {%Battery{level: level}, rest}

  defp decode_one(
         <<0x01, up, yaw_face, yaw::little-signed-16, pitch::little-signed-16,
           roll::little-signed-16, ax::little-signed-16, ay::little-signed-16,
           az::little-signed-16, gx::little-signed-16, gy::little-signed-16, gz::little-signed-16,
           rest::binary>>
       ) do
    imu = %ImuValues{
      up_face: Enums.to_name(:hub_face, up),
      yaw_face: Enums.to_name(:hub_face, yaw_face),
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      accelerometer_x: ax,
      accelerometer_y: ay,
      accelerometer_z: az,
      gyroscope_x: gx,
      gyroscope_y: gy,
      gyroscope_z: gz
    }

    {imu, rest}
  end

  defp decode_one(<<0x02, pixels::binary-size(25), rest::binary>>),
    do: {%MatrixDisplay5x5{pixels: :binary.bin_to_list(pixels)}, rest}

  defp decode_one(
         <<0x0A, port, type, absolute::little-signed-16, power::little-signed-16, speed::signed-8,
           position::little-signed-32, rest::binary>>
       ) do
    motor = %Motor{
      port: Enums.to_name(:hub_port, port),
      device_type: Enums.to_name(:motor_device_type, type),
      absolute_position: absolute,
      power: power,
      speed: speed,
      position: position
    }

    {motor, rest}
  end

  defp decode_one(<<0x0B, port, value, pressed, rest::binary>>) do
    {%ForceSensor{port: Enums.to_name(:hub_port, port), value: value, pressed: pressed == 1},
     rest}
  end

  defp decode_one(
         <<0x0C, port, color, red::little-16, green::little-16, blue::little-16, rest::binary>>
       ) do
    sensor = %ColorSensor{
      port: Enums.to_name(:hub_port, port),
      color: Enums.to_name(:color, color),
      red: red,
      green: green,
      blue: blue
    }

    {sensor, rest}
  end

  defp decode_one(<<0x0D, port, distance::little-signed-16, rest::binary>>),
    do: {%DistanceSensor{port: Enums.to_name(:hub_port, port), distance: distance}, rest}

  defp decode_one(<<0x0E, port, pixels::binary-size(9), rest::binary>>) do
    {%ColorMatrix3x3{port: Enums.to_name(:hub_port, port), pixels: :binary.bin_to_list(pixels)},
     rest}
  end

  defp decode_one(<<id, data::binary>>), do: {%Unknown{id: id, data: data}, <<>>}

  @doc """
  Encodes a list of device messages into a device notification payload.

      iex> ExSPIKE.Device.encode([%ExSPIKE.Device.Battery{level: 87}])
      <<0x00, 87>>
  """
  @spec encode([t()]) :: binary()
  def encode(messages) when is_list(messages) do
    for message <- messages, into: <<>>, do: encode_one(message)
  end

  defp encode_one(%Battery{level: level}), do: <<0x00, level>>

  defp encode_one(%ImuValues{} = imu) do
    <<0x01, Enums.to_value(:hub_face, imu.up_face), Enums.to_value(:hub_face, imu.yaw_face),
      imu.yaw::little-signed-16, imu.pitch::little-signed-16, imu.roll::little-signed-16,
      imu.accelerometer_x::little-signed-16, imu.accelerometer_y::little-signed-16,
      imu.accelerometer_z::little-signed-16, imu.gyroscope_x::little-signed-16,
      imu.gyroscope_y::little-signed-16, imu.gyroscope_z::little-signed-16>>
  end

  defp encode_one(%MatrixDisplay5x5{pixels: pixels}) when length(pixels) == 25,
    do: <<0x02, :binary.list_to_bin(pixels)::binary>>

  defp encode_one(%Motor{} = motor) do
    <<0x0A, Enums.to_value(:hub_port, motor.port),
      Enums.to_value(:motor_device_type, motor.device_type),
      motor.absolute_position::little-signed-16, motor.power::little-signed-16,
      motor.speed::signed-8, motor.position::little-signed-32>>
  end

  defp encode_one(%ForceSensor{port: port, value: value, pressed: pressed}),
    do: <<0x0B, Enums.to_value(:hub_port, port), value, if(pressed, do: 1, else: 0)>>

  defp encode_one(%ColorSensor{} = sensor) do
    <<0x0C, Enums.to_value(:hub_port, sensor.port), Enums.to_value(:color, sensor.color),
      sensor.red::little-16, sensor.green::little-16, sensor.blue::little-16>>
  end

  defp encode_one(%DistanceSensor{port: port, distance: distance}),
    do: <<0x0D, Enums.to_value(:hub_port, port), distance::little-signed-16>>

  defp encode_one(%ColorMatrix3x3{port: port, pixels: pixels}) when length(pixels) == 9,
    do: <<0x0E, Enums.to_value(:hub_port, port), :binary.list_to_bin(pixels)::binary>>

  defp encode_one(%Unknown{id: id, data: data}), do: <<id, data::binary>>
end
