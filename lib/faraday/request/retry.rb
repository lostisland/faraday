module Faraday
  # Catches exceptions and retries each request a limited number of times.
  #
  # By default, it retries 2 times and handles only timeout exceptions. It can
  # be configured with an arbitrary number of retries, a list of exceptions to
  # handle an a retry interval.
  #
  # Examples
  #
  #   Faraday.new do |conn|
  #     conn.request :retry, max: 2, interval: 0.05,
  #                          exceptions: [CustomException, 'Timeout::Error']
  #     conn.adapter ...
  #   end
  class Request::Retry < Faraday::Middleware
    # Public: Initialize middleware
    #
    # Options:
    # max        - Maximum number of retries (default: 2).
    # interval   - Pause in seconds between retries (default: 0).
    # exceptions - The list of exceptions to handle. Exceptions can be
    #              given as Class, Module, or String. (default:
    #              [Errno::ETIMEDOUT, Timeout::Error, Error::TimeoutError])
    def initialize(app, options = {})
      super(app)
      @retries, options = options, {} if options.is_a? Integer
      @retries ||= options.fetch(:max, 2).to_i
      @sleep     = options.fetch(:interval, 0).to_f
      to_handle  = options.fetch(:exceptions) {
                     [Errno::ETIMEDOUT, 'Timeout::Error', Error::TimeoutError]
                   }
      @errmatch  = build_exception_matcher Array(to_handle)
    end

    def call(env)
      retries = @retries
      begin
        @app.call(env)
      rescue @errmatch
        if retries > 0
          retries -= 1
          sleep @sleep if @sleep > 0
          retry
        end
        raise
      end
    end

    # Private: construct an exception matcher object.
    #
    # An exception matcher for the rescue clause can usually be any object that
    # responds to `===`, but for Ruby 1.8 it has to be a Class or Module.
    def build_exception_matcher(exceptions)
      matcher = Module.new
      (class << matcher; self; end).class_eval do
        define_method(:===) do |error|
          exceptions.any? do |ex|
            if ex.is_a? Module then error.is_a? ex
            else error.class.to_s == ex.to_s
            end
          end
        end
      end
      matcher
    end
  end
end
