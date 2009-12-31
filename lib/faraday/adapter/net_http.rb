require 'net/http'
require 'cgi'
module Faraday
  module Adapter
    module NetHttp
      extend Faraday::Connection::Options

      def _perform(method, uri, data, request_headers)
        http = Net::HTTP.new(uri.host, uri.port)
        response_class.new do |resp|
          http_resp = http.send_request(method, uri.path, data, request_headers)
          raise Faraday::Error::ResourceNotFound if http_resp.code == '404'
          resp.process http_resp.body
          http_resp.each_header do |key, value|
            resp.headers[key] = value
          end
        end
      rescue Errno::ECONNREFUSED
        raise Faraday::Error::ConnectionFailed, "connection refused"
      end

      def _put(uri, data, request_headers)
        _perform('PUT', uri, encode_params(data), request_headers)
      end

      def _post(uri, data, request_headers)
        _perform('POST', uri, encode_params(data), request_headers)
      end

      def _get(uri, request_headers)
        _perform('GET', uri, uri.query, request_headers)
      end

      def _delete(uri, request_headers)
        _perform('DELETE', uri, uri.query, request_headers)
      end

    end
  end
end
