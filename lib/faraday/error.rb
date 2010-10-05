module Faraday
  module Error
    class ClientError      < StandardError; end
    class ConnectionFailed < ClientError;   end
    class ResourceNotFound < ClientError;   end
    class ParsingError     < ClientError;   end
  end
end
