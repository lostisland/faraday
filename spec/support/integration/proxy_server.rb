# frozen_string_literal: true

require 'socket'
require 'uri'

module Faraday
  module IntegrationHelpers
    # Minimal forward proxy running in a background thread, used to exercise
    # ProxyOptions. It supports plain HTTP forwarding, CONNECT tunnelling and
    # optional Basic proxy authentication, and records what it was asked to do
    # so specs can assert that traffic really went through it.
    class ProxyServer
      Request = Struct.new(:http_method, :target, :headers)

      attr_reader :port, :requests

      # @param credentials [Array<String>, nil] `[user, password]` required via
      #   Proxy-Authorization; when nil the proxy is open
      # @param hosts [Hash{String => Array}] maps `"host:port"` targets to the
      #   `[host, port]` actually connected to, which lets specs use fake host
      #   names (needed because Ruby never proxies requests to loopback hosts
      #   when the proxy comes from the environment)
      def initialize(credentials: nil, hosts: {})
        @credentials = credentials
        @hosts = hosts
        @requests = []
        @threads = []
        @server = TCPServer.new('127.0.0.1', 0)
        @port = @server.addr[1]
      end

      def self.start(...)
        new(...).start
      end

      def start
        @acceptor = Thread.new do
          loop { @threads << Thread.new(@server.accept) { |client| handle(client) } }
        rescue IOError, Errno::EBADF
          nil # server stopped
        end
        self
      end

      def stop
        @server.close
        @acceptor&.join(1)
        @threads.each { |thread| thread.join(1) }
      end

      def url
        "http://127.0.0.1:#{port}"
      end

      private

      def handle(client)
        request = read_request(client)
        return unless request

        @requests << request
        if !authorized?(request)
          reject(client)
        elsif request.http_method == 'CONNECT'
          tunnel(client, request.target)
        else
          forward(client, request)
        end
      rescue SystemCallError, IOError
        nil # a peer went away
      ensure
        client.close unless client.closed?
      end

      def read_request(client)
        method, target, = client.gets.to_s.split
        return unless method

        headers = {}
        while (line = client.gets)
          break if line.strip.empty?

          name, value = line.split(':', 2)
          headers[name.strip.downcase] = value.to_s.strip
        end
        Request.new(method, target, headers)
      end

      def authorized?(request)
        return true unless @credentials

        request.headers['proxy-authorization'] == "Basic #{[@credentials.join(':')].pack('m0')}"
      end

      def reject(client)
        client.write("HTTP/1.1 407 Proxy Authentication Required\r\n" \
                     "Proxy-Authenticate: Basic realm=\"faraday\"\r\n" \
                     "Content-Length: 0\r\n" \
                     "Connection: close\r\n\r\n")
      end

      def forward(client, request)
        uri = URI.parse(request.target)
        upstream = connect_upstream(uri.host, uri.port)

        upstream.write("#{request.http_method} #{uri.request_uri} HTTP/1.1\r\n")
        request.headers.each do |name, value|
          upstream.write("#{name}: #{value}\r\n") unless name.start_with?('proxy-') || name == 'connection'
        end
        upstream.write("Connection: close\r\n\r\n")

        length = request.headers['content-length'].to_i
        upstream.write(client.read(length)) if length.positive?

        IO.copy_stream(upstream, client)
      ensure
        upstream&.close
      end

      def tunnel(client, target)
        host, port = target.split(':')
        upstream = connect_upstream(host, port.to_i)
        client.write("HTTP/1.1 200 Connection established\r\n\r\n")

        relay(client, upstream) until client.closed? || upstream.closed?
      ensure
        upstream&.close
      end

      # Copies whatever is readable from one side to the other and closes both on EOF
      def relay(client, upstream)
        IO.select([client, upstream]).first.each do |source|
          data = source.read_nonblock(16_384, exception: false)
          if data.nil?
            client.close
            upstream.close
            break
          end
          (source.equal?(client) ? upstream : client).write(data) unless data == :wait_readable
        end
      end

      def connect_upstream(host, port)
        TCPSocket.new(*@hosts.fetch("#{host}:#{port}", [host, port]))
      end
    end
  end
end
