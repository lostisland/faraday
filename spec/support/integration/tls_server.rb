# frozen_string_literal: true

require 'json'
require 'openssl'
require 'socket'

module Faraday
  module IntegrationHelpers
    # Minimal HTTPS server running in a background thread, used to exercise
    # SSLOptions and ProxyOptions against real TLS handshakes.
    #
    # Every request is answered with a JSON document describing what the server
    # saw, e.g. `{"path":"/","client_cert_subject":null,"remote_ip":"127.0.0.1"}`.
    class TLSServer
      attr_reader :port

      # @param credentials [TestPKI::Credentials] server certificate and key
      # @param client_ca [TestPKI, nil] when given, clients must present a
      #   certificate signed by this CA (mutual TLS)
      # @param host [String] address to listen on; '0.0.0.0' makes the server
      #   reachable from service containers, such as the proxies
      def initialize(credentials, client_ca: nil, host: '127.0.0.1')
        @tcp_server = TCPServer.new(host, 0)
        @port = @tcp_server.addr[1]
        @ssl_server = OpenSSL::SSL::SSLServer.new(@tcp_server, ssl_context(credentials, client_ca))
        @ssl_server.start_immediately = false
        @threads = []
      end

      def self.start(...)
        new(...).start
      end

      def start
        @acceptor = Thread.new do
          loop do
            socket = @ssl_server.accept
            @threads << Thread.new { handle(socket) }
          end
        rescue IOError, Errno::EBADF
          nil # server stopped
        end
        self
      end

      def stop
        @ssl_server.close
        @acceptor&.join(1)
        @threads.each { |thread| thread.join(1) }
      end

      def url(host = 'localhost')
        "https://#{host}:#{port}"
      end

      private

      def ssl_context(credentials, client_ca)
        OpenSSL::SSL::SSLContext.new.tap do |ctx|
          ctx.cert = credentials.cert
          ctx.key = credentials.key
          if client_ca
            ctx.cert_store = client_ca.cert_store
            ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
          end
        end
      end

      def handle(socket)
        socket.accept
        request_line = socket.gets
        while (line = socket.gets)
          break if line.strip.empty?
        end
        respond(socket, request_line.to_s.split[1])
      rescue OpenSSL::SSL::SSLError, SystemCallError, IOError
        nil # the client rejected the handshake or went away
      ensure
        socket.close unless socket.closed?
      end

      def respond(socket, path)
        body = JSON.generate(path: path, client_cert_subject: socket.peer_cert&.subject&.to_s,
                             remote_ip: socket.io.remote_address.ip_address)
        socket.write("HTTP/1.1 200 OK\r\n" \
                     "Content-Type: application/json\r\n" \
                     "Content-Length: #{body.bytesize}\r\n" \
                     "Connection: close\r\n\r\n#{body}")
      end
    end
  end
end
