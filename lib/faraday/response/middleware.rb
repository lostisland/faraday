module Faraday
  # A base class for middleware that parses responses
  class Response::Middleware < Faraday::Middleware
    # Executes a block which should try to require and reference dependent libraries
    def self.dependency
      yield
    rescue LoadError, NameError => error
      self.load_error = error
    end

    class << self
      attr_accessor :parser
    end

    # Stores a block that receives the body and should return a parsed result
    def self.define_parser(&block)
      @parser = block
    end

    def self.inherited(subclass)
      super
      subclass.load_error = self.load_error
      subclass.parser = self.parser
    end

    def call(env)
      env[:response].on_complete do |finished_env|
        on_complete(finished_env)
      end
      @app.call(env)
    end

    # Override this to modify the environment after the response has finished.
    def on_complete(env)
      env[:body] = parse(env[:body])
    end

    # Parses the response body and returns the result.
    # Instead of overriding this method, consider using `define_parser`
    def parse(body)
      if self.class.parser
        begin
          self.class.parser.call(body)
        rescue
          raise Faraday::Error::ParsingError, $!
        end
      else
        body
      end
    end
  end
end
