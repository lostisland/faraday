module Faraday
  class Response < Struct.new(:headers, :body)
    class << self
      attr_accessor :load_error
      def loaded?
        !load_error
      end
    end

    extend AutoloadHelper
    autoload_all 'faraday/response', 
      :YajlResponse => 'yajl_response'

    def initialize(headers = nil, body = nil)
      super(headers || {}, body)
      if block_given?
        yield self
        processed!
      end
    end

    # TODO: process is a funky name.  change it
    # processes a chunk of the streamed body.
    def process(chunk)
      if !body
        self.body = []
      end
      body << chunk
    end

    # Assume the given content is the full body, and not streamed.  
    def process!(full_body)
      process(full_body)
      processed!
    end

    # Signals the end of streamed content.  Do whatever you need to clean up
    # the streamed body.
    def processed!
      self.body = body.join if body.respond_to?(:join)
    end
  end
end