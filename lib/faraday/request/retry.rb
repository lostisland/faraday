module Faraday
  class Request::Retry < Faraday::Middleware
    def initialize(app, options = {})
      super(app)
      @retries, options = options, {} if options.is_a? Integer
      @retries ||= options.fetch(:max, 2).to_i
      @sleep     = options.fetch(:interval, 0).to_f
      to_handle  = options.fetch(:exceptions) {
                     [Errno::ETIMEDOUT, 'Timeout::Error', Error::TimeoutError]
                   }
      @errmatch  = ExceptionMatcher.new Array(to_handle)
    end

    class ExceptionMatcher < Struct.new(:exceptions)
      def ===(error)
        exceptions.any? do |ex|
          if ex.is_a? Module then error.is_a? ex
          else error.class.to_s == ex.to_s
          end
        end
      end
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
  end
end
