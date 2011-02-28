module Faraday
  module Error
    class ClientError < StandardError
      def initialize(ex)
        super(ex.respond_to?(:message) ? ex.message : ex.to_s)
        @wrapped_exception = ex
      end

      def backtrace
        @wrapped_exception.backtrace
      end

      alias to_str message

      def to_s
        @wrapped_exception.to_s
      end

      def inspect
        %(#<#{self.class}>)
      end
    end

    class ConnectionFailed < ClientError;   end
    class ResourceNotFound < ClientError;   end
    class ParsingError     < ClientError;   end
  end
end
