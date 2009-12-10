require 'yajl'
module Faraday
  class Response
    class YajlResponse < Response
      attr_reader :body

      def initialize(headers = nil, body = nil)
        super
        @parser = nil
      end

      def process(chunk)
        if !@parser
          @parser = Yajl::Parser.new
          @parser.on_parse_complete = method(:object_parsed)
        end
        @parser << chunk
      end

      def processed!
        @parser = nil
      end

      def object_parsed(obj)
        @body = obj
      end
    end
  end
end
