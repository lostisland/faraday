module Faraday
  class Response
    extend AutoloadHelper

    autoload_all 'faraday/response',
      :JSON       => 'json',
      :Middleware => 'middleware'

    register_lookup_modules \
      :json => :JSON

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

    # because @on_complete_callbacks cannot be marshalled
    def marshal_dump
      [@status, @headers, @body]
    end

    def marshal_load(data)
      @status, @headers, @body = data
    end
  end
end
