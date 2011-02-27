module Faraday
  class Response
    # A base class for middleware that parses responses
    class Middleware < Faraday::Middleware
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

    extend AutoloadHelper

    autoload_all 'faraday/response',
      :Yajl              => 'yajl',
      :ActiveSupportJson => 'active_support_json'

    register_lookup_modules \
      :yajl                => :Yajl,
      :activesupport_json  => :ActiveSupportJson,
      :rails_json          => :ActiveSupportJson,
      :active_support_json => :ActiveSupportJson
    attr_accessor :status, :headers, :body

    def initialize
      @status, @headers, @body = nil, nil, nil
      @on_complete_callbacks = []
    end

    def on_complete(&block)
      @on_complete_callbacks << block
    end

    def finish(env)
      return self if @status
      env[:body]             ||= ''
      env[:response_headers] ||= {}
      @on_complete_callbacks.each { |c| c.call(env) }
      @status, @headers, @body = env[:status], env[:response_headers], env[:body]
      self
    end

    def success?
      status == 200
    end
  end
end
