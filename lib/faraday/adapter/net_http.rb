require 'net/http'
module Faraday
  module Adapter
    module NetHttp
      def _get(uri, request_headers)
        http = Net::HTTP.new(uri.host, uri.port)
        resp = http.get(uri.path, request_headers)
        headers = {}
        resp.each_header do |key, value|
          headers[key] = value
        end
        Faraday::Response.new(headers, resp.body)
      end
    end
  end
end
