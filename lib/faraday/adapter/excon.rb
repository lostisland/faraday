module Faraday
  class Adapter
    class Excon < Faraday::Adapter
      begin
        require 'excon'
      rescue LoadError, NameError => e
        self.load_error = e
      end

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

        env.update \
          :status => resp.status.to_i,
          :response_headers => {},
          :body => resp.body

        resp.headers.each do |key, value|
          env[:response_headers][key.downcase] = value
        end

        @app.call env
      rescue ::Excon::Errors::SocketError
        raise Error::ConnectionFailed, $!
      end
    end
  end
end
