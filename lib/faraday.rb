module Faraday
  # Loads each autoloaded constant.  If thread safety is a concern, wrap
  # this in a Mutex.
  def self.load
    constants.each do |const|
      const_get(const) if autoload?(const)
    end
  end

  autoload :Connection, 'faraday/connection'

  class Response < Struct.new(:headers, :body)
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
  end

  module Adapter
    autoload :NetHttp, 'faraday/adapter/net_http'
  end
end