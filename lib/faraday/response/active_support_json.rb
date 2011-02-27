module Faraday
  class Response::ActiveSupportJson < Response::Middleware
    dependency do
      require 'active_support/json/decoding'
      ActiveSupport::JSON
    end
    
    define_parser do |body|
      ActiveSupport::JSON.decode(body)
    end
  end
end
