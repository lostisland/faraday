# frozen_string_literal: true

begin
  require 'net/https'
rescue LoadError
  warn 'Warning: no such file to load -- net/https. ' \
    'Make sure openssl is installed if you want ssl support'
  require 'net/http'
end
require 'zlib'

module Faraday
  class Adapter
    # Net::HTTP adapter.
    class NetHttp < Faraday::Adapter
      exceptions = [
        IOError,
        Errno::EADDRNOTAVAIL,
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EINVAL,
        Errno::ENETUNREACH,
        Errno::EPIPE,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        SocketError,
        Zlib::GzipFile::Error
      ]

      exceptions << OpenSSL::SSL::SSLError if defined?(OpenSSL)
      exceptions << Net::OpenTimeout if defined?(Net::OpenTimeout)

      NET_HTTP_EXCEPTIONS = exceptions.freeze

      def initialize(app = nil, opts = {}, &block)
        @ssl_cert_store = nil
        super(app, opts, &block)
      end

      def call(env)
        super
        with_net_http_connection(env) do |http|
          if (env[:url].scheme == 'https') && env[:ssl]
            configure_ssl(http, env[:ssl])
          end
          configure_request(http, env[:request])

          begin
            http_response = perform_request(http, env)
          rescue *NET_HTTP_EXCEPTIONS => err
            if defined?(OpenSSL) && err.is_a?(OpenSSL::SSL::SSLError)
              raise Faraday::SSLError, err
            end

            raise Faraday::ConnectionFailed, err
          end

          save_response(env, http_response.code.to_i,
                        http_response.body || '', nil,
                        http_response.message) do |response_headers|
            http_response.each_header do |key, value|
              response_headers[key] = value
            end
          end
        end

        @app.call env
      rescue Timeout::Error, Errno::ETIMEDOUT => err
        raise Faraday::TimeoutError, err
      end

      private

      def with_net_http_connection(env)
        yield net_http_connection(env)
      end

      def net_http_connection(env)
        klass = if (proxy = env[:request][:proxy])
                  Net::HTTP::Proxy(proxy[:uri].hostname, proxy[:uri].port,
                                   proxy[:user], proxy[:password])
                else
                  Net::HTTP
                end
        port = env[:url].port || (env[:url].scheme == 'https' ? 443 : 80)
        klass.new(env[:url].hostname, port)
      end
    end
  end
end

require 'faraday/adapter/net_http/request_configuration'
require 'faraday/adapter/net_http/request_execution'
