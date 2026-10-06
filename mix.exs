defmodule ExSPIKE.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ErikMejerHansen/ex_spike"

  def project do
    [
      app: :ex_spike,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      name: "ExSPIKE",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def cli do
    [preferred_envs: [spec: :test]]
  end

  def application do
    [extra_applications: []]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      # Runs the tests and writes spec/STATUS.md
      spec: ["test --formatter ExUnit.CLIFormatter --formatter ExSPIKE.SpecFormatter"]
    ]
  end

  defp description do
    "Stateless encoder/decoder for the LEGO® SPIKE™ Prime BLE protocol. " <>
      "Not affiliated with, sponsored or endorsed by The LEGO Group."
  end

  defp package do
    [
      name: "ex_spike",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "SPIKE Prime protocol docs" => "https://lego.github.io/spike-prime-docs/"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: [
        Codec: [ExSPIKE, ExSPIKE.Message, ExSPIKE.Device, ExSPIKE.Messages],
        "Wire format": [ExSPIKE.Frame, ExSPIKE.COBS, ExSPIKE.CRC, ExSPIKE.Enums],
        Messages: ~r/^ExSPIKE\.Message\./,
        "Device messages": ~r/^ExSPIKE\.Device\./
      ]
    ]
  end
end
