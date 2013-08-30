module Faraday
  class Request::Retry < Faraday::Middleware
    def initialize(app, retries = 2)
      @retries = retries
      super(app)
    end

    def call(env)
      retries = @retries
      request_body = env[:body]
      begin
        env[:body] = request_body # after failure env[:body] is set to the response body
        @app.call(env)
      rescue StandardError, Timeout::Error
        if retries > 0
          retries -= 1
          retry
        end
        raise
      end
    end
  end
end
