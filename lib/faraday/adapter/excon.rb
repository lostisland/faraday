module Faraday
  class Adapter
    class Excon < Faraday::Adapter
      dependency 'excon'

      def call(env)
        super

        conn = ::Excon.new(env[:url].to_s)
        if ssl = (env[:url].scheme == 'https' && env[:ssl])
          ::Excon.ssl_verify_peer = !!ssl.fetch(:verify, true)
          ::Excon.ssl_ca_path = ssl[:ca_file] if ssl[:ca_file]
        end

        resp = conn.request \
          :method  => env[:method].to_s.upcase,
          :headers => env[:request_headers],
          :body    => env[:body]

        env.update :status => resp.status.to_i, :body => resp.body
        response_headers(env).update resp.headers

        @app.call env
      rescue ::Excon::Errors::SocketError
        raise Error::ConnectionFailed, $!
      end
    end
  end
end
