require 'yajl'
module Faraday
  class Response
    class DelayedYajlResponse < YajlResponse
      def content
        self
      end
    end
  end
end