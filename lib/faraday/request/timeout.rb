module Faraday
  class Request::Timeout < Faraday::Middleware
    dependency "timeout"

    def initialize(app, timeout = 2)
      self.class.dependency "system_timer" if ruby18?
      @timeout = timeout
      super(app)
    end

    def call(env)
      method =
      if ruby18? && self.class.loaded?
        SystemTimer.method(:timeout_after)
      else
        Timeout.method(:timeout)
      end

      method.call(@timeout) do
        @app.call(env)
      end
    end

    private

    def ruby18?
      @ruby18 ||= RUBY_VERSION =~ /^1\.8/
    end

  end
end
