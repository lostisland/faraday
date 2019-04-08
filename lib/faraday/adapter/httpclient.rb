# frozen_string_literal: true

module Faraday
  class Adapter
    # HTTPClient adapter.
    class HTTPClient < Faraday::Adapter
      dependency 'httpclient'

      # @return [HTTPClient]
      def client
        @client ||= ::HTTPClient.new
      end

      def call(env)
        super

        # enable compression
        client.transparent_gzip_decompression = true

        if (req = env[:request])
          if (proxy = req[:proxy])
            configure_proxy proxy
          end

          if (bind = req[:bind])
            configure_socket bind
          end

          configure_timeouts req
        end

        if env[:url].scheme == 'https' && (ssl = env[:ssl])
          configure_ssl ssl
        end

        configure_client

        # TODO: Don't stream yet.
        # https://github.com/nahi/httpclient/pull/90
        env[:body] = env[:body].read if env[:body].respond_to? :read

        resp = client.request env[:method], env[:url],
                              body: env[:body],
                              header: env[:request_headers]

        if (req = env[:request]).stream_response?
          warn "Streaming downloads for #{self.class.name} " \
            'are not yet implemented.'
          req.on_data.call(resp.body, resp.body.bytesize)
        end
        save_response env, resp.status, resp.body, resp.headers, resp.reason

        @app.call env
      rescue ::HTTPClient::TimeoutError, Errno::ETIMEDOUT
        raise Faraday::TimeoutError, $ERROR_INFO
      rescue ::HTTPClient::BadResponseError => e
        if e.message.include?('status 407')
          raise Faraday::ConnectionFailed,
                %(407 "Proxy Authentication Required ")
        end

        raise Faraday::ClientError, $ERROR_INFO
      rescue Errno::EADDRNOTAVAIL, Errno::ECONNREFUSED, IOError, SocketError
        raise Faraday::ConnectionFailed, $ERROR_INFO
      rescue StandardError => e
        if defined?(OpenSSL) && e.is_a?(OpenSSL::SSL::SSLError)
          raise Faraday::SSLError, e
        end

        raise
      end

      # @param bind [Hash]
      def configure_socket(bind)
        client.socket_local.host = bind[:host]
        client.socket_local.port = bind[:port]
      end

      # Configure proxy URI and any user credentials.
      #
      # @param proxy [Hash]
      def configure_proxy(proxy)
        client.proxy = proxy[:uri]
        return unless proxy[:user] && proxy[:password]

        client.set_proxy_auth(proxy[:user], proxy[:password])
      end

      # @param ssl [Hash]
      def configure_ssl(ssl)
        ssl_config = client.ssl_config
        ssl_config.verify_mode = ssl_verify_mode(ssl)
        ssl_config.cert_store = ssl_cert_store(ssl)

        ssl_config.add_trust_ca ssl[:ca_file]        if ssl[:ca_file]
        ssl_config.add_trust_ca ssl[:ca_path]        if ssl[:ca_path]
        ssl_config.client_cert  = ssl[:client_cert]  if ssl[:client_cert]
        ssl_config.client_key   = ssl[:client_key]   if ssl[:client_key]
        ssl_config.verify_depth = ssl[:verify_depth] if ssl[:verify_depth]
      end

      # @param req [Hash]
      def configure_timeouts(req)
        configure_timeout(req) if req[:timeout]
        configure_open_timeout(req) if req[:open_timeout]
      end

      def configure_timeout(req)
        client.connect_timeout   = req[:timeout]
        client.receive_timeout   = req[:timeout]
        client.send_timeout      = req[:timeout]
      end

      def configure_open_timeout(req)
        client.connect_timeout   = req[:open_timeout]
        client.send_timeout      = req[:open_timeout]
      end

      def configure_client
        @config_block&.call(client)
      end

      # @param ssl [Hash]
      # @return [OpenSSL::X509::Store]
      def ssl_cert_store(ssl)
        return ssl[:cert_store] if ssl[:cert_store]

        # Memoize the cert store so that the same one is passed to
        # HTTPClient each time, to avoid resyncing SSL sessions when
        # it's changed
        @ssl_cert_store ||= begin
          # Use the default cert store by default, i.e. system ca certs
          OpenSSL::X509::Store.new.tap(&:set_default_paths)
        end
      end

      # @param ssl [Hash]
      def ssl_verify_mode(ssl)
        ssl[:verify_mode] || begin
          if ssl.fetch(:verify, true)
            OpenSSL::SSL::VERIFY_PEER |
              OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
          else
            OpenSSL::SSL::VERIFY_NONE
          end
        end
      end
    end
  end
end
