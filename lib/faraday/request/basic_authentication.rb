require 'base64'

module Faraday
  class Request::BasicAuthentication < Request::Authorization
    # Public
    def self.header(login, pass)
      value = Base64.strict_encode64([login, pass].join(':'))
      super(:Basic, value)
    end
  end
end

