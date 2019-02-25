# frozen_string_literal: true

require 'base64'

module Faraday
  # Authorization middleware for Basic Authentication.
  class Request::BasicAuthentication < Request.load_middleware(:authorization)
    # @param login [String]
    # @param pass [String]
    #
    # @return [String] a Basic Authentication header line
    def self.header(login, pass)
      value = Base64.encode64([login, pass].join(':'))
      value.gsub!("\n", '')
      super(:Basic, value)
    end
  end
end
