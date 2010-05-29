module Faraday
  module Error
    class ClientError      < StandardError; end
    class ConnectionFailed < ClientError;   end
    class ResourceNotFound < ClientError;   end
  end
end
