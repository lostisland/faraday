module Faraday
  class Request::Retry < Faraday::Middleware
    def initialize(app, retries = 2, options = {})
      @retries = retries
      @exceptions = options[:on]
      super(app)
    end

    def call(env)
      retries = @retries
      begin
        @app.call(env)
      rescue *@exceptions || Error::TimeoutError
        if retries > 0
          retries -= 1
          retry
        end
        raise
      end
    end
  end
end
