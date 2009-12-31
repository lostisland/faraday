module Faraday
  module Request
    class YajlRequest
      extend Loadable

      begin
        require 'yajl'

        def initialize params
          @params = params
        end

        # TODO streaming
        def encode
          Yajl::Encoder.encode @params
        end
      rescue LoadError => e
        self.load_error = e
      end
    end
  end
end
