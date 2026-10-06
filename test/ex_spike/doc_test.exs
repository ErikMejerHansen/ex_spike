defmodule ExSPIKE.DocTest do
  use ExUnit.Case, async: true

  doctest ExSPIKE
  doctest ExSPIKE.COBS
  doctest ExSPIKE.CRC
  doctest ExSPIKE.Device
  doctest ExSPIKE.Enums
  doctest ExSPIKE.Frame
  doctest ExSPIKE.Message
  doctest ExSPIKE.Messages
end
