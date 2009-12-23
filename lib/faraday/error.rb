module Faraday
  module Error
    class ConnectionFailed < StandardError; end
    class ResourceNotFound < StandardError; end
  end
end
