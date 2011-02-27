module Faraday
  class Response::Yajl < Response::Middleware
    dependency do
      require 'yajl'
      Yajl::Parser
    end
    
    define_parser do |body|
      Yajl::Parser.parse(body)
    end
  end
end
