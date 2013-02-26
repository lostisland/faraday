module Faraday
  class Adapter

    class RackClient < Faraday::Adapter
      dependency 'rack/client'

      def initialize(faraday_app, rack_client_adapter = :default, *a, &b)
        klass = case rack_client_adapter
                when :default then ::Rack::Client
                when :simple  then ::Rack::Client::Simple
                when :base    then ::Rack::Client::Base
                else rack_client_adapter
                end

        @rack_client_app = klass.new(*a, &b)
      end

      def call(env)
        @rack_client_app.call(env)
      end

    end
  end
end
