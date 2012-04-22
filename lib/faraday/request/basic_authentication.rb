require 'base64'

module Faraday
  class Request::BasicAuthentication < Request::Authorization
    def self.build(login, pass)
      value = Base64.encode64([login, pass].join(':'))
      value.gsub!("\n", '')
      super(:Basic, value)
    end
  end
end

