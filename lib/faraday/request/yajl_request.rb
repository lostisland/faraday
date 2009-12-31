module Faraday
  module Request
    class YajlRequest
      extend Loadable

      begin
        require 'yajl'

        def initialize params, headers={}
          @params = params
          @headers = headers
        end

        def headers
          @headers.merge('Content-Type' => 'application/json')
        end

        # TODO streaming
        def body
          Yajl::Encoder.encode @params
        end
      rescue LoadError => e
        self.load_error = e
      end
    end
  end
end
