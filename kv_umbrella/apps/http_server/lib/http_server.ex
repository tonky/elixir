defmodule HTTPServer do
  use Application
  require Logger
  require IO

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
  	  supervisor(Task.Supervisor, [[name: HTTPServer.TaskSupervisor]]),
  	  worker(Task, [HTTPServer, :accept, [4041]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HTTPServer.Supervisor]
    Supervisor.start_link(children, opts)
    # Logger.info "Accepting connections on port 4041"
  end

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, listen_socket} = :gen_tcp.listen(port, [active: false, reuseaddr: true])

    do_accept(listen_socket)
  end
  
  defp do_accept(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    # {:ok, pid} = Task.Supervisor.start_child(HTTPServer.TaskSupervisor, fn -> respond(socket) end)
    # :ok = :gen_tcp.controlling_process(socket, pid)
    spawn(fn() -> respond(socket) end)
	do_accept(listen_socket)
  end

  def respond(socket) do
	socket |> read_socket |> parse_request |> write_response(socket)
  end

  def read_socket(socket) do
    :gen_tcp.recv(socket, 0)
  end

  def parse_request(raw_read) do
	case raw_read do
	  {:ok, data} ->
		{:ok, String.split(to_string(data), "\r\n")}
	  # {:error, :closed} ->
	  #   Logger.error("Can't read data from socket")
	end
  end

  def write_response(data, socket) do
	resp = """
HTTP/1.1 200 OK
Content-Length: 4
Content-Type: text/html
Connection: Closed

test
"""

	:gen_tcp.send socket, resp
	:gen_tcp.close socket
  end
end
