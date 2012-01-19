module Faraday
  class Request::Retry < Faraday::Middleware
    def initialize(app, retries = 2)
      @retries = retries
      super(app)
    end

    def call(env)
      retries = @retries
      begin
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
