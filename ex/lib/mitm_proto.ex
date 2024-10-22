defmodule Mitm.Proto do
  use GenServer

  def init(_) do
    {:ok, %{}}
  end

  def connect_addr(address, port) do
    IO.inspect({:connect, address, port})
    {address, port}
  end

  def on_connect(flow = %{dest: socket}) do
    :inet.setopts(socket, [{:active, true}, :binary])
    Map.merge(flow, %{start_time: :os.system_time(1), buf_s: <<>>, buf_c: <<>>})
  end

  def on_close(socket, state) do
    state
  end

  # server conn
  def proc_packet(:server, bin, s) do
    IO.puts("<- #{s.dest_addr} #{s.dest_port}")
    buf = s.buf_s <> bin
    {packets, buf} = unpad(buf)
    s = Map.put(s, :buf_s, buf)
    IO.inspect(packets)
    {:send, bin, s}
  end

  # client conn
  def proc_packet(:client, bin, s) do
    IO.puts("-> #{s.dest_addr} #{s.dest_port}")
    buf = s.buf_c <> bin
    {packets, buf} = unpad(buf)
    s = Map.put(s, :buf_c, buf)
    IO.inspect(packets)
    {:send, bin, s}
  end

  def unpad(data) do
    unpad(data, [])
  end

  def unpad(<<len::32-little, data::binary>> = all, acc) do
    l = len - 16

    case all do
      <<_::32-little, op::32-little, count::32-little, crc::32-little, data::binary-size(l),
        rest::binary>> ->
        pop = Bitwise.band(0xFFFF, op)
        top = Protocol.Opcode.from_num(pop) || pop
        unpad(rest, [{top, count, crc, data} || acc])

      _ ->
        {:lists.reverse(acc), all}
    end
  end

  def unpad(rest, acc) do
    {:lists.reverse(acc), rest}
  end
end
