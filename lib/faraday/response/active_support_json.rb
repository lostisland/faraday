module Faraday
  class Response::ActiveSupportJson < Faraday::Middleware
    begin
      if !defined?(ActiveSupport::JSON)
        require 'active_support'
        ActiveSupport::JSON
      end
    rescue LoadError, NameError => e
      self.load_error = e
    end

    def initialize(app)
      super
      @parser = nil
    end

    def call(env)
      env[:response].on_complete do |finished_env|
        finished_env[:body] = parse(finished_env[:body])
      end
      @app.call(env)
    end

    def parse(body)
      ActiveSupport::JSON.decode(body)
    rescue Object
      raise Faraday::Error::ParsingError, $!
    end
  end
end
