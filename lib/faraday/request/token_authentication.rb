# frozen_string_literal: true

require 'faraday/request/authorization'

module Faraday
  class Request
    # TokenAuthentication is a middleware that adds a 'Token' header to a
    # Faraday request.
    class TokenAuthentication < Authorization
      # Public
      def self.header(token, options = nil)
        options ||= {}
        options[:token] = token
        super(:Token, options)
      end

      def initialize(app, token, options = nil)
        super(app, token, options)
      end
    end
  end
end

Faraday::Request.register_middleware(token_auth: Faraday::Request::TokenAuthentication)
