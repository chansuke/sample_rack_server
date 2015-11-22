require 'rack'
require 'socket'
require 'sinatra'

class RackServer
  STATUS_CODE = {
    200 => 'OK',
    404 => 'Error'
    500 => 'Internal Server Error'
  }

  attr_reader :app, :tcp_server

  def initialize(app)
    @app = app
  end

  def start
    @tcp_server = TCPServer.new('localhost', 8080)
    puts 'Listening on port 8080...'

    loop do
      socket   = tcp_server.accept
      request  = socket.gets
      response = ''

      env = env(*request.split)
      status, headers, body = app.call(env)

      response << "HTTP/1.1 #{status} #{STATUS_CODE[status]}\r\n"
      headers.each do |k, v|
        response << "#{k}: #{v}\r\n"
      end
      response << "Connection close\r\n"

      socket.print response
      socket.print "\r\n"

      if body.is_a?(String)
        socket.print body
      else
        body.each do |chunk|
          socket.print chunk
        end
      end

      socket.close
    end
  end

  def env(method, location, *args)
    {
      'REQUEST_METHOD'   => method,
      'SCRIPT_NAME'      => '',
      'PATH_INFO'        => location,
      'QUERY_STRING'     => location.split('?').last,
      'SERVER_NAME'      => 'localhost',
      'SERVER_POST'      => '8080',
      'rack.version'     => Rack.version.split('.'),
      'rack.url_scheme'  => 'http',
      'rack.input'       => StringIO.new(''),
      'rack.errors'      => StringIO.new(''),
      'rack.multithread' => false,
      'rack.run_once'    => false
    }
  end
end
