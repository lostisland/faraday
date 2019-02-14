require 'forwardable'

module Faraday
  class Response
    extend Forwardable
    extend MiddlewareRegistry

    register_middleware File.expand_path('../response', __FILE__),
                        :raise_error => [:RaiseError, 'raise_error'],
                        :logger => [:Logger, 'logger']

    attr_accessor :status, :body, :headers, :reason_phrase

    SuccessfulStatuses = 200..299

    def initialize(**params)
      apply_params(params)
      @on_complete_callbacks = []
      @finished = false
    end

    def_delegator :headers, :[]

    def finished?
      @finished
    end

    def on_complete(&block)
      if !finished?
        @on_complete_callbacks << block
      else
        yield(self)
      end
      self
    end

    def finish(**params)
      raise "response already finished" if finished?
      apply_params(params) unless params.include?(:ssl)
      @finished = true
      @on_complete_callbacks.each { |callback| callback.call(self) }
      self
    end

    # @return [Boolean] true if status is in the set of {SuccessfulStatuses}.
    def success?
      finished? && SuccessfulStatuses.include?(status)
    end

    # because @on_complete_callbacks cannot be marshalled
    def marshal_dump
      !finished? ? nil : {
        :status => status, :body => body,
        :headers => headers, :reason_phrase => reason_phrase
      }
    end

    def marshal_load(payload)
      apply_params(payload)
    end

    def apply_params(status: nil, body: nil, headers: {}, reason_phrase: nil)
      @status = status
      @body = body
      @headers = headers.is_a?(Utils::Headers) ? headers : Utils::Headers.from(headers)
      @reason_phrase = reason_phrase
    end
  end
end
