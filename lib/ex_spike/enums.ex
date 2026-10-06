defmodule ExSPIKE.Enums do
  @moduledoc """
  The enumerations of the SPIKE™ Prime protocol, mapped to atoms.

  | Enum                    | Values |
  | ----------------------- | ------ |
  | `:product_group_device` | `:spike_prime` |
  | `:color`                | `:black`, `:magenta`, `:purple`, `:blue`, `:azure`, `:turquoise`, `:green`, `:yellow`, `:orange`, `:red`, `:white`, `:unknown` |
  | `:hub_port`             | `:a`, `:b`, `:c`, `:d`, `:e`, `:f` |
  | `:hub_face`             | `:top`, `:front`, `:right`, `:bottom`, `:back`, `:left` |
  | `:program_action`       | `:start`, `:stop` |
  | `:response_status`      | `:acknowledged`, `:not_acknowledged` |
  | `:motor_end_state`      | `:coast`, `:brake`, `:hold`, `:continue`, `:smart_coast`, `:smart_brake`, `:default` |
  | `:motor_move_direction` | `:clockwise`, `:counter_clockwise`, `:shortest_path`, `:longest_path` |
  | `:motor_device_type`    | `:medium_motor`, `:large_motor`, `:small_motor` |

  Values without a known name are passed through as integers, so decoding
  never fails because of a newer firmware adding enum values.

  See [Enumerations](https://lego.github.io/spike-prime-docs/enums.html).
  """

  @enums %{
    product_group_device: [spike_prime: 0x0000],
    color: [
      black: 0x00,
      magenta: 0x01,
      purple: 0x02,
      blue: 0x03,
      azure: 0x04,
      turquoise: 0x05,
      green: 0x06,
      yellow: 0x07,
      orange: 0x08,
      red: 0x09,
      white: 0x0A,
      unknown: 0xFF
    ],
    hub_port: [a: 0x00, b: 0x01, c: 0x02, d: 0x03, e: 0x04, f: 0x05],
    hub_face: [top: 0x00, front: 0x01, right: 0x02, bottom: 0x03, back: 0x04, left: 0x05],
    program_action: [start: 0x00, stop: 0x01],
    response_status: [acknowledged: 0x00, not_acknowledged: 0x01],
    motor_end_state: [
      coast: 0x00,
      brake: 0x01,
      hold: 0x02,
      continue: 0x03,
      smart_coast: 0x04,
      smart_brake: 0x05,
      default: 0xFF
    ],
    motor_move_direction: [
      clockwise: 0x00,
      counter_clockwise: 0x01,
      shortest_path: 0x02,
      longest_path: 0x03
    ],
    motor_device_type: [medium_motor: 0x30, large_motor: 0x31, small_motor: 0x41]
  }

  @type enum ::
          :product_group_device
          | :color
          | :hub_port
          | :hub_face
          | :program_action
          | :response_status
          | :motor_end_state
          | :motor_move_direction
          | :motor_device_type

  @doc """
  Returns the named values of `enum` as a keyword list.

      iex> ExSPIKE.Enums.values(:program_action)
      [start: 0, stop: 1]
  """
  @spec values(enum()) :: keyword(non_neg_integer())
  def values(enum), do: Map.fetch!(@enums, enum)

  @doc """
  Converts a name (or a raw integer) to its wire value.

      iex> ExSPIKE.Enums.to_value(:hub_port, :c)
      2

      iex> ExSPIKE.Enums.to_value(:hub_port, 2)
      2
  """
  @spec to_value(enum(), atom() | non_neg_integer()) :: non_neg_integer()
  def to_value(_enum, value) when is_integer(value), do: value

  def to_value(enum, name) when is_atom(name) do
    case Keyword.fetch(values(enum), name) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "unknown #{enum} value: #{inspect(name)}"
    end
  end

  @doc """
  Converts a wire value to its name, or returns the integer if it has none.

      iex> ExSPIKE.Enums.to_name(:color, 0x09)
      :red

      iex> ExSPIKE.Enums.to_name(:color, 0x42)
      0x42
  """
  @spec to_name(enum(), non_neg_integer()) :: atom() | non_neg_integer()
  def to_name(enum, value) when is_integer(value) do
    Enum.find_value(values(enum), value, fn {name, v} -> v == value && name end)
  end
end
