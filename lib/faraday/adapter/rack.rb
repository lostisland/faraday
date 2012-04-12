require 'timeout'
module Faraday
  class Adapter
    # This adapter wraps around a rack app, similar to how Rack::Test
    # allows you to test rack apps.
    #
    # @example
    #    class RackApp
    #      def call(env)
    #        [200, {'Content-Type' => 'text/html'}, ["hello world"]]
    #      end
    #    end
    #
    #    Faraday.new do |builder|
    #      builder.adapter :rack, RackApp
    #    end
    class Rack < Faraday::Adapter
      dependency 'rack/test'

      begin
        if RUBY_VERSION < '1.9'
          require 'system_timer'
        end
      rescue LoadError
        $stderr.puts "Faraday: you may want to install system_timer for reliable timeouts"
      ensure
        SystemTimer ||= Timeout
      end

      # @param app [Faraday::Middleware]
      # @param rack rack application to wrap
      def initialize(app, rack)
        super(app)
        mock_session = ::Rack::MockSession.new(rack)
        @session     = ::Rack::Test::Session.new(mock_session)
      end

      def call(env)
        super
        rack_env = {
          :method => env[:method],
          :input  => env[:body].respond_to?(:read) ? env[:body].read : env[:body]
        }

        if env[:request_headers]
          env[:request_headers].each do |k,v|
            rack_env[k.upcase.gsub('-', '_')] = v
          end
        end

        timeout  = env[:request][:timeout] || env[:request][:open_timeout]
        response = if timeout
          SystemTimer.timeout(timeout, Faraday::Error::TimeoutError) {
            execute_request(env, rack_env)
          }
        else
          execute_request(env, rack_env)
        end
        save_response(env, response.status, response.body, response.headers)
        @app.call env
      end

      # @private
      def execute_request(env, rack_env)
        @session.request(env[:url].to_s, rack_env)
      end
    end
  end
end