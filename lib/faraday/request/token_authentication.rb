module Faraday
  class Request::TokenAuthentication < Request::Authorization
    # Public
    def self.build(token, options = nil)
      options ||= {}
      options[:token] = token
      super :Token, options
    end

    def initialize(app, token, options = nil)
      super(app, token, options)
    end
  end
end

