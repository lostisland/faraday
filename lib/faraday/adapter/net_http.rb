require 'net/http'
require 'cgi'
module Faraday
  module Adapter
    module NetHttp
      extend Faraday::Connection::Options

      def _post(uri, data, request_headers)
        http = Net::HTTP.new(uri.host, uri.port)
        response_class.new do |resp|
          post_data = post_encode(data)
          http_resp = http.post(uri.path, post_data, request_headers) do |chunk|
            resp.process(chunk)
          end
          http_resp.each_header do |key, value|
            resp.headers[key] = value
          end
        end
      end

      def _get(uri, request_headers)
        http = Net::HTTP.new(uri.host, uri.port)
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

      def post_encode data
        create_post_params data
      end
    
     private
      def create_post_params(params, base = "")
        [].tap do |toreturn|
          params.each_key do |key|
            keystring = base == '' ? key : "#{base}[#{key}]"
            toreturn << (params[key].kind_of?(Hash) ? create_post_params(params[key], keystring) : "#{keystring}=#{CGI.escape(params[key].to_s)}")
          end
        end.join('&')
      end
    end
  end
end
