require 'net/http'
module Faraday
  module Adapter
    module NetHttp
      def self.loaded() true end

      def _get(uri, request_headers)
        http      = Net::HTTP.new(uri.host, uri.port)
        response_class.new do |resp|
          http_resp = http.get(uri.path, request_headers) do |chunk|
            resp.process(chunk)
          end
          http_resp.each_header do |key, value|
            resp.headers[key] = value
          end
        end
      end
    end
  end
end
