module Faraday::RackBuilder::Response
  extend Faraday::MiddlewareRegistry

  register_middleware File.expand_path('../response', __FILE__),
    :raise_error => [:RaiseError, 'raise_error'],
    :logger => [:Logger, 'logger']

  # Used for simple response middleware.
  class Middleware < Faraday::RackBuilder::Middleware
    def call(env)
      @app.call(env).on_complete do |environment|
        on_complete(environment)
      end
    end

    # Override this to modify the environment after the response has finished.
    # Calls the `parse` method if defined
    def on_complete(env)
      env.body = parse(env.body) if respond_to?(:parse) && env.parse_body?
    end
  end
end

