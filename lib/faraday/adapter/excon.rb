module Faraday
  class Adapter
    class Excon < Faraday::Adapter
      dependency 'excon'

      def call(env)
        super

        opts = {}
        if env[:url].scheme == 'https' && ssl = env[:ssl]
          opts[:ssl_verify_peer] = !!ssl.fetch(:verify, true)
          opts[:ssl_ca_path] = ssl[:ca_file] if ssl[:ca_file]
        end
        conn = ::Excon.new(env[:url].to_s, opts)

        resp = conn.request \
          :method  => env[:method].to_s.upcase,
          :headers => env[:request_headers],
          :body    => env[:body]

        save_response(env, resp.status.to_i, resp.body, resp.headers)

        @app.call env
      rescue ::Excon::Errors::SocketError
        raise Error::ConnectionFailed, $!
      end
    end
  end
end
