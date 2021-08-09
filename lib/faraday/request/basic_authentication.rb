# frozen_string_literal: true

require 'base64'
require 'faraday/request/authorization'

module Faraday
  class Request
    # Authorization middleware for Basic Authentication.
    class BasicAuthentication < Authorization
      # @param login [String]
      # @param pass [String]
      #
      # @return [String] a Basic Authentication header line
      def self.header(login, pass)
        value = Base64.encode64([login, pass].join(':'))
        value.delete!("\n")
        super(:Basic, value)
      end
    end
  end
end

Faraday::Request.register_middleware(basic_auth: Faraday::Request::BasicAuthentication)
