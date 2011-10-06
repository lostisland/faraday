module Faraday
  class Request::Timeout < Faraday::Middleware
    dependency "timeout"

    def initialize(app, timeout = 2)
      @timeout = timeout
      super(app)
    end

    def call(env)
      Timeout::timeout(@timeout) do
        @app.call(env)
      end
    end
  end
end
