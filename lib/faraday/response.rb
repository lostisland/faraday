module Faraday
  class Response
    # Used for simple response middleware that parse the incoming body into 
    # a ruby object.  Expects a #parse instance method.
    class Middleware < Faraday::Middleware
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
