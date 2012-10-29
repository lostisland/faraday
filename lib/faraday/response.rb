require 'forwardable'

module Faraday
  class Response
    extend Forwardable

    def initialize(env = nil)
      @env = Env.from(env) if env
      @on_complete_callbacks = []
    end

    attr_reader :env

    def_delegators :env, :to_hash

    def status
      finished? ? env.status : nil
    end

    def headers
      finished? ? env.response_headers : {}
    end
    def_delegator :headers, :[]

    def body
      finished? ? env.body : nil
    end

    def finished?
      !!env
    end

    def on_complete
      if not finished?
        @on_complete_callbacks << Proc.new
      else
        yield env
      end
      return self
    end

    def finish(env)
      raise "response already finished" if finished?
      @env = Env.from(env)
      @on_complete_callbacks.each { |callback| callback.call(env) }
      return self
    end

    def success?
      finished? && env.success?
    end

    # because @on_complete_callbacks cannot be marshalled
    def marshal_dump
      !finished? ? nil : {
        :status => @env.status, :body => @env.body,
        :response_headers => @env.response_headers
      }
    end

    def marshal_load(env)
      @env = Env.from(env)
    end

    # Expand the env with more properties, without overriding existing ones.
    # Useful for applying request params after restoring a marshalled Response.
    def apply_request(request_env)
      raise "response didn't finish yet" unless finished?
      @env = Env.from(request_env).merge(@env)
      return self
    end
  end
end

