require 'net/http'
module Faraday
  module Adapter
    module NetHttp
      def _get(uri, request_headers)
        http      = Net::HTTP.new(uri.host, uri.port)
        resp      = Response.new({})
        http_resp = http.get(uri.path, request_headers) do |chunk|
          resp.process(chunk)
        end
        resp.processed!
        http_resp.each_header do |key, value|
          resp.headers[key] = value
        end
        resp
      end
    end
  end
end
