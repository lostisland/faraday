require 'base64'

module Faraday
  class Request::BasicAuthentication < Faraday::Middleware
    def initialize(app, login, pass)
      super(app)
      @header_value = "Basic #{Base64.encode64([login, pass].join(':')).gsub("\n", '')}"
    end

    def call(env)
      unless env[:request_headers]['Authorization']
        env[:request_headers]['Authorization'] = @header_value
      end
      @app.call(env)
    end
  end
end
