defmodule Ex do
  @moduledoc """
  Documentation for `Ex`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Ex.hello()
      :world

  """
  def hello do
    :world
  end
end

defmodule Snip do
  def trim_elixir(mod) when is_list(mod) do
    Enum.map(mod, &String.to_atom(String.trim("#{&1}", "Elixir.")))
  end

  def trim_elixir(mod) do
    String.to_atom(String.trim("#{mod}", "Elixir."))
  end

  defmodule Locallink do
    def route(_, source, dest, dest_port) do
      IO.inspect({:route, source, dest, dest_port})

      case {source, dest, dest_port} do
        # {_, _, 80} -> %{uplink: nil, module: Mitm.Hexdump} #master server
        # master server
        {_, _, 33004} -> %{uplink: nil, module: Mitm.Lobby}
        # game server
        {_, _, 35001} -> %{uplink: nil, module: Mitm.Game}
        _ -> %{module: Raw, uplink: nil}
      end
    end
  end

  defmodule S5link do
    def route(_, source, dest, dest_port) do
      if dest_port != 443 do
        IO.inspect({:route, source, dest, dest_port})
      end

      case {source, dest, dest_port} do
        # master server
        {_, _, p} when p in [30204, 20000, 10000, 4000] ->
          %{uplink: nil, module: Mitm.Proto}

        # {_, _, _} ->
        #  proxy = %{
        #    host: "http://49.0.246.161:3344",
        #    ip: "49.0.246.161",
        #    password: "aa1111",
        #    port: 3344,
        #    type: :socks5,
        #    username: "aa1111"
        #  }
        #
        #  %{uplink: proxy, module: Raw }

        _ ->
          %{module: Raw, uplink: nil}
      end
    end
  end

  def locallink(router \\ Snip.S5link) do
    specs = [
      %{port: 31332, router: router},
      %{port: 9021, router: router, listener_type: :sock5}
    ]

    # DNS.Server2Sup.start_link(%{
    #  static_names: %{"live-dl.nightcrows.com" => {172, 0, 0, 1}},
    #  uplink_server: "1.1.1.1",
    #  proxy: {"127.0.0.1", 1080}
    # })

    # {:ok, _} = DynamicSupervisor.start_child(NC.Supervisor, %{
    #  id: MitmConns,
    #  start: {Mitme.Acceptor.Supervisor, :start_link, [[locallink]]}})
    {:ok, _} = Mitme.Acceptor.Supervisor.start_link(specs)
  end

  def link_s5(specs \\ %{port: 9021, router: Snip.S5link, listener_type: :sock5}) do
    # {:ok, _} = DynamicSupervisor.start_child(NC.Supervisor, %{
    #  id: MitmConns,
    #  start: {Mitme.Acceptor.Supervisor, :start_link, [[locallink]]}})

    #    DNS.Server2Sup.start_link(
    #      %{
    #        static_names: %{"live-dl.nightcrows.co.kr" => "172.0.0.1"},
    #        uplink_server: "1.1.1.1",
    #        proxy: {"192.168.2.153", 1080}
    #      },
    #      max_restarts: 99999999999
    #    )

    {:ok, _} = Mitme.Acceptor.Supervisor.start_link([specs])
  end
end

defmodule Mitm.Hexdump2 do
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
    Map.merge(flow, %{start_time: :os.system_time(1)})
  end

  def on_close(socket, state) do
    state
  end

  # server conn
  def proc_packet(:server, bin, s) do
    IO.puts("<- #{s.dest_addr} #{s.dest_port}")
    IO.puts(Hexdump.to_string(bin))
    {:send, bin, s}
  end

  # client conn
  def proc_packet(:client, bin, s) do
    IO.puts("-> #{s.dest_addr} #{s.dest_port}")
    IO.puts(Hexdump.to_string(bin))
    {:send, bin, s}
  end
end
