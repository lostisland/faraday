module Faraday
  # Faraday error base class.
  class Error < StandardError; end

  # Faraday client error class.
  class ClientError < Error
    attr_reader :response, :wrapped_exception

    def initialize(ex, response = nil)
      @wrapped_exception = nil
      @response = response

      if ex.respond_to?(:backtrace)
        super(ex.message)
        @wrapped_exception = ex
      elsif ex.respond_to?(:each_key)
        super("the server responded with status #{ex[:status]}")
        @response = ex
      else
        super(ex.to_s)
      end
    end

    def backtrace
      if @wrapped_exception
        @wrapped_exception.backtrace
      else
        super
      end
    end

    def inspect
      inner = ''
      if @wrapped_exception
        inner << " wrapped=#{@wrapped_exception.inspect}"
      end
      if @response
        inner << " response=#{@response.inspect}"
      end
      if inner.empty?
        inner << " #{super}"
      end
      %(#<#{self.class}#{inner}>)
    end
  end

  class ConnectionFailed < ClientError;   end
  class ResourceNotFound < ClientError;   end
  class ParsingError     < ClientError;   end

  class TimeoutError < ClientError
    def initialize(ex = nil)
      super(ex || "timeout")
    end
  end

  class SSLError < ClientError
  end

  class RetriableResponse < ClientError; end

  [:ClientError, :ConnectionFailed, :ResourceNotFound,
   :ParsingError, :TimeoutError, :SSLError, :RetriableResponse].each do |const|
    Error.const_set(const, Faraday.const_get(const))
  end


end
