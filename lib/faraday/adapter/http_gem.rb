module Faraday
  class Adapter
    class HttpGem < Faraday::Adapter
      dependency 'http'

      def initialize(app, options = {})
        @client = ::HTTP::Client.new options
        super(app)
      end

      def call(env)
        super

        # TODO: Support streaming.
        #   HTTP gem expects body to be String or Enumerable,
        env[:body] = env[:body].read if env[:body].respond_to? :read

        begin
          res = @client.request(env[:method], env[:url], {
            :body => env[:body],
            :headers => env[:request_headers],
            :proxy => proxy_options(env)
          })
        rescue Errno::ECONNREFUSED => e
          raise Error::ConnectionFailed, e
        end

        save_response env, res.status, res.to_s, res.headers.to_h

        @app.call env
      end

      private

      def proxy_options(env)
        return unless env[:request][:proxy]

        hash = {
          :proxy_address => env[:request][:proxy][:uri].host,
          :proxy_port    => env[:request][:proxy][:uri].port
        }

        if env[:request][:proxy][:user]
          hash[:proxy_username] = env[:request][:proxy][:user]
          hash[:proxy_password] = env[:request][:proxy][:password]
        end

        hash
      end
    end
  end
end
