module Faraday
  class Adapter
    class Excon < Faraday::Adapter
      dependency 'excon'

      def call(env)
        super

        conn = ::Excon.new(env[:url].to_s)
        if env[:url].scheme == 'https' && ssl = env[:ssl]
          ::Excon.ssl_verify_peer = !!ssl.fetch(:verify, true)
          ::Excon.ssl_ca_path = ssl[:ca_file] if ssl[:ca_file]
        end

        resp = conn.request \
          :method  => env[:method].to_s.upcase,
          :headers => env[:request_headers],
          :body    => env[:body]

        if want_streaming?(env)
          warn "Streaming downloads for Excon are not yet implemented."
          env[:on_data].call(resp.body, resp.body.bytesize)
        end
        save_response(env, resp.status.to_i, resp.body, resp.headers)

        @app.call env
      rescue ::Excon::Errors::SocketError
        raise Error::ConnectionFailed, $!
      end
    end
  end
end
