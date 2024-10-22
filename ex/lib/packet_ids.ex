defmodule Protocol.Opcode do
  ids =
    File.read!("opcodes.cs")
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&String.replace(&1, "public const ePacketId ", ""))
    |> Enum.map(&String.split(&1, " = "))
    |> Enum.map(fn [a, b] -> {a, String.to_integer(b)} end)

  as_map =
    Enum.map(ids, fn {a, b} -> {b, :erlang.binary_to_atom(a)} end)
    |> Map.new()

  as_map_reverse =
    Enum.map(ids, fn {a, b} -> {:erlang.binary_to_atom(a), b} end)
    |> Map.new()

  def from_num(x) do
    unquote(Macro.escape(as_map)) |> Map.get(x)
  end

  def to_num(x) do
    unquote(Macro.escape(as_map_reverse)) |> Map.get(x)
  end
end
