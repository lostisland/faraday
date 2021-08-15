# frozen_string_literal: true

require 'base64'

module Faraday
  class Request
    # Request middleware for the Authorization HTTP header
    class Authorization < Faraday::Middleware
      unless defined?(::Faraday::Request::Authorization::KEY)
        KEY = 'Authorization'
      end

      # @param app [#call]
      # @param type [String, Symbol] Type of Authorization
      # @param params [Array<String, Proc>] parameters to build the Authorization header.
      #   If the type is `:basic`, then these can be a login and password pair.
      #   Otherwise, a single value is expected that will be appended after the type.
      #   This value can be a proc, in which case it will be invoked on each request.
      def initialize(app, type, *params)
        @type = type
        @params = params
        super(app)
      end

      # @param env [Faraday::Env]
      def on_request(env)
        return if env.request_headers[KEY]

        env.request_headers[KEY] = header_from(@type, *@params)
      end

      private

      # @param type [String, Symbol]
      # @param params [Array]
      # @return [String] a header value
      def header_from(type, *params)
        if type.to_s.casecmp('basic').zero? && params.size == 2
          basic_header_from(*params)
        elsif params.size != 1
          raise ArgumentError, "Unexpected params received (got #{params.size} instead of 1)"
        else
          value = params.first
          value = value.call if value.is_a?(Proc)
          "#{type} #{value}"
        end
      end

      def basic_header_from(login, pass)
        value = Base64.encode64("#{login}:#{pass}")
        value.delete!("\n")
        "Basic #{value}"
      end
    end
  end
end
