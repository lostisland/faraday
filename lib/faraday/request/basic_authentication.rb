require 'base64'

module Faraday
  class Request::BasicAuthentication < Faraday::Middleware
    def initialize(app, login, pass)
      super(app)
      @header_value = "Basic #{Base64.encode64([login, pass].join(':')).gsub("\n", '')}"
    end

    def call(env)
      env[:request_headers]['Authorization'] = @header_value
      @app.call(env)
    end
  end
end