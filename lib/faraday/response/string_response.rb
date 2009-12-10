module Faraday
  class Response
    class StringResponse < Response
      def content
        body
      end
    end
  end
end