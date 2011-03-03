module Faraday
  class Response
    # Used for simple response middleware.
    class Middleware < Faraday::Middleware
      def call(env)
        @app.call(env).on_complete do |env|
          on_complete(env)
        end
      end

      # Override this to modify the environment after the response has finished.
      def on_complete(env)
        # env[:body]
      end
    end

    extend AutoloadHelper

    autoload_all 'faraday/response',
      :RaiseError => 'raise_error'

    register_lookup_modules \
      :raise_error => :RaiseError

    def initialize(env = nil)
      @finished_env = env
      @on_complete_callbacks = []
    end

    def status
      @finished_env ? @finished_env[:status] : nil
    end

    def headers
      @finished_env ? @finished_env[:response_headers] : nil
    end

    def body
      @finished_env ? @finished_env[:body] : nil
    end

    def finished?
      !!@finished_env
    end

    def on_complete
      if not finished?
        @on_complete_callbacks << Proc.new
      else
        yield @finished_env
      end
      return self
    end

    def finish(env)
      raise "response already finished" if finished?
      @finished_env = env
      env[:body] ||= ''
      env[:response_headers] ||= {}
      @on_complete_callbacks.each { |callback| callback.call(env) }
      return self
    end

    def success?
      status == 200
    end

    # because @on_complete_callbacks cannot be marshalled
    def marshal_dump
      @finished_env.nil? ? nil : {
        :status           => @finished_env[:status],
        :response_headers => @finished_env[:response_headers],
        :body             => @finished_env[:body]
      }
    end

    def marshal_load(env)
      @finished_env = env
    end
  end
end
