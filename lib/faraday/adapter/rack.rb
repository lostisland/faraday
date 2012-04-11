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
        else
          require 'timeout'
        end
        SystemTimer ||= Timeout
      rescue LoadError
        $stderr.puts "Faraday: you may want to install system_timer to reliable timeouts"
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

        timeout = env[:request][:timeout] || env[:request][:open_timeout]
        SystemTimer.timeout(timeout, Faraday::Error::TimeoutError) do
          response = @session.request(env[:url].to_s, rack_env)
          save_response(env, response.status, response.body, response.headers)
        end
        @app.call env
      end
    end
  end
end