require 'net/http'
module Faraday
  module Adapter
    module NetHttp
      extend Faraday::Connection::Options
      self.loaded = true

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
      rescue Errno::ECONNREFUSED
        raise Faraday::Error::ConnectionFailed, "connection refused"
      end
    end
  end
end
