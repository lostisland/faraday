module Faraday
  class Adapter

    class RackClient < Faraday::Adapter
      dependency 'rack/client'

      def initialize(faraday_app, rack_client_adapter = :default, *a, &b)
        super(faraday_app)

        klass = case rack_client_adapter
                when :default then ::Rack::Client
                when :simple  then ::Rack::Client::Simple
                when :base    then ::Rack::Client::Base
                else rack_client_adapter
                end

        @rack_client_app = klass.new(*a, &b)
      end

      def call(faraday_env)
        rack_env      = to_rack_env(faraday_env)
        rack_response = @rack_client_app.call(rack_env)

        status, headers, body = rack_response

        save_response(faraday_env, status, body.join, headers)

        @app.call faraday_env
      end

      def to_rack_env(faraday_env)
        body = faraday_env.body
        body = body.read if body.respond_to? :read

        @rack_client_app.build_env(faraday_env.method.to_s.upcase,
                                   faraday_env.url.to_s,
                                   faraday_env.request_headers,
                                   body)
      end

    end
  end
end
