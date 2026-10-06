defmodule ExSPIKE.DeviceTest do
  use ExUnit.Case, async: true

  alias ExSPIKE.Device

  @examples [
    {%Device.Battery{level: 87}, <<0x00, 87>>},
    {%Device.ImuValues{
       up_face: :top,
       yaw_face: :front,
       yaw: -1,
       pitch: 2,
       roll: -3,
       accelerometer_x: 4,
       accelerometer_y: -5,
       accelerometer_z: 6,
       gyroscope_x: -7,
       gyroscope_y: 8,
       gyroscope_z: -9
     },
     <<0x01, 0x00, 0x01, -1::little-16, 2::little-16, -3::little-16, 4::little-16, -5::little-16,
       6::little-16, -7::little-16, 8::little-16, -9::little-16>>},
    {%Device.MatrixDisplay5x5{pixels: Enum.to_list(0..24)},
     <<0x02, :binary.list_to_bin(Enum.to_list(0..24))::binary>>},
    {%Device.Motor{
       port: :a,
       device_type: :large_motor,
       absolute_position: -180,
       power: -10_000,
       speed: -100,
       position: -2_147_483_648
     },
     <<0x0A, 0x00, 0x31, -180::little-16, -10_000::little-16, -100, -2_147_483_648::little-32>>},
    {%Device.ForceSensor{port: :b, value: 100, pressed: true}, <<0x0B, 0x01, 100, 0x01>>},
    {%Device.ColorSensor{port: :c, color: :red, red: 1023, green: 512, blue: 0},
     <<0x0C, 0x02, 0x09, 1023::little-16, 512::little-16, 0::little-16>>},
    {%Device.DistanceSensor{port: :d, distance: -1}, <<0x0D, 0x03, 0xFF, 0xFF>>},
    {%Device.ColorMatrix3x3{port: :f, pixels: Enum.to_list(1..9)},
     <<0x0E, 0x05, 1, 2, 3, 4, 5, 6, 7, 8, 9>>}
  ]

  for {message, bytes} <- @examples do
    name = message.__struct__ |> Module.split() |> List.last()

    describe "Given a #{name} device message" do
      test "when encoded, then it produces the documented bytes" do
        assert Device.encode([unquote(Macro.escape(message))]) == unquote(bytes)
      end

      test "when its bytes are decoded, then the struct is restored" do
        assert Device.decode(unquote(bytes)) == [unquote(Macro.escape(message))]
      end
    end
  end

  describe "Given a color sensor that detects no color" do
    test "when decoded, then the color is :unknown" do
      assert [%Device.ColorSensor{color: :unknown}] = Device.decode(<<0x0C, 0x02, 0xFF, 0::48>>)
    end
  end

  describe "Given a payload with several device messages" do
    test "when decoded, then every message is returned in order" do
      payload = <<0x00, 87, 0x0B, 0x01, 42, 0x00, 0x0D, 0x00, 100, 0>>

      assert Device.decode(payload) == [
               %Device.Battery{level: 87},
               %Device.ForceSensor{port: :b, value: 42, pressed: false},
               %Device.DistanceSensor{port: :a, distance: 100}
             ]
    end
  end

  describe "Given a payload containing an unknown device message" do
    test "when decoded, then known messages are kept and the rest is returned as Unknown" do
      assert Device.decode(<<0x00, 87, 0x99, 1, 2, 3>>) == [
               %Device.Battery{level: 87},
               %Device.Unknown{id: 0x99, data: <<1, 2, 3>>}
             ]
    end

    test "when re-encoded, then the original bytes are produced" do
      payload = <<0x00, 87, 0x99, 1, 2, 3>>
      assert payload |> Device.decode() |> Device.encode() == payload
    end
  end
end
