module Faraday
  class Middleware
    extend MiddlewareRegistry
    extend DependencyLoader

    def initialize(app = nil)
      @app = app
    end

    # Calls `on_request` and `on_complete`
    def call(env)
      on_request(env) if respond_to?(:on_request)
      @app.call(env).on_complete do |_|
        on_complete(env)
      end
    end

    # Override this to modify the environment after the response has finished.
    # Calls the `parse` method if defined
    def on_complete(env)
      env.response.body = parse(env.response.body) if respond_to?(:parse) && env.parse_body?
    end
  end
end
