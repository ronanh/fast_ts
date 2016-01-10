defmodule FastTS.Server do

  @doc """
  Starts accepting connections on the give `port`.
  """
  @spec accept(port :: integer) :: no_return
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 4, active: false, reuseaddr: true])
    # TODO move to logger
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  # TODO Fixme, we can only support one client
  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    # {:ok, pid} = Task.Supervisor.start_child(Fast.Stream.Server, fn -> serve(client) end)
    # :ok = :gen_tcp.controlling_process(client, pid)
    serve(client)
    loop_acceptor(socket)
  end

  def serve(socket) do
    # TODO Use Elixir logger
    IO.puts "Client connected"
    socket
    |> read_message
    |> send_response
  end

  defp read_message(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    process_data(data)
    socket
  end

  defp send_response(socket) do
    msg = RiemannProto.Msg.encode(RiemannProto.Msg.new(ok: true))
    :gen_tcp.send(socket, msg)
  end

  defp process_data(data) do
    RiemannProto.Msg.decode(data)
    |> extract_events
    |> Enum.map(&stream_event/1)
  end
  
  defp extract_events(%RiemannProto.Msg{events: events}), do: events
  defp extract_events(_), do: []

  defp stream_event(event) do
    # TODO:
    # - Do not use a hardcoded router module name (allow registering with the use macro from router ?)
    # - Catch to avoid crash and report errors
    HelloFast.Router.stream event
  end

end

# TODO:
# - Ignore messages with outdated ttl
# - Fix issue with parallel / spawn execution
