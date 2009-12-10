module Faraday
  class Response < Struct.new(:headers, :body)
    autoload :StringResponse, 'faraday/response/string_response'
    autoload :YajlResponse,   'faraday/response/yajl_response'

    def initialize(headers = nil, body = nil)
      super(headers || {}, body)
      if block_given?
        yield self
        processed!
      end
    end

    def process(chunk)
      if !body
        self.body = []
      end
      body << chunk
    end

    def processed!
      self.body = body.join if body.respond_to?(:join)
    end

    # determines what Faraday::Connection#get returns
    def content
      self
    end
  end
end