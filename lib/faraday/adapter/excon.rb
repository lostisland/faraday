module Faraday
  class Adapter
    class Excon < Faraday::Adapter
      dependency 'excon'

      def initialize(app, connection_options = {})
        @connection_options = connection_options
        super(app)
      end

      def call(env)
        super

        opts = {}
        if env[:url].scheme == 'https' && ssl = env[:ssl]
          opts[:ssl_verify_peer] = !!ssl.fetch(:verify, true)
          opts[:ssl_ca_path] = ssl[:ca_file] if ssl[:ca_file]
        end

        if ( req = env[:request] )
          if req[:timeout]
            opts[:read_timeout]      = req[:timeout]
            opts[:connect_timeout]   = req[:timeout]
            opts[:write_timeout]     = req[:timeout]
          end

          if req[:open_timeout]
            opts[:connect_timeout]   = req[:open_timeout]
            opts[:write_timeout]     = req[:open_timeout]
          end
        end

        conn = ::Excon.new(env[:url].to_s, opts.merge(@connection_options))

        resp = conn.request \
          :method  => env[:method].to_s.upcase,
          :headers => env[:request_headers],
          :body    => read_body(env)

        save_response(env, resp.status.to_i, resp.body, resp.headers)

        @app.call env
      rescue ::Excon::Errors::SocketError
        raise Error::ConnectionFailed, $!
      rescue ::Excon::Errors::Timeout => err
        raise Faraday::Error::TimeoutError, err
      end

      # TODO: support streaming requests
      def read_body(env)
        env[:body].respond_to?(:read) ? env[:body].read : env[:body]
      end
    end
  end
end
