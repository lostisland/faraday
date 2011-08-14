require 'http_client'

module Faraday
  class Adapter
    class HTTPClient < Faraday::Adapter
      def call(env)
        super
        
        # Remove any non-parameter keys
        method = env.delete(:method) || :get
        req    = env.delete(:request)
        url    = env.delete(:url).to_s
        client_opts = env.delete(:client_options) || {}

        http = HTTP::Client.new client_opts.merge(:default_host => url)
        http.timeout_in_seconds = req[:timeout]    if req[:timeout]
        http.default_proxy      = req[:proxy].to_s if req[:proxy]
        http.connection_timeout = req[:open_timeout] * 1000 if req[:open_timeout]
        
        request = HTTP.const_get(method.to_s.capitalize).new(url, env)
        request.add_headers env.delete(:request_headers)
        begin
          http_response = http.execute request
        rescue NativeException => exception
          if exception =~ /^org.apache.http.conn.HttpHostConnectException/
            raise Error::ConnectionFailed, $!
          else
            raise exception
          end
        end

        save_response(env, http_response.status_code, http_response.body) do |response_headers|
          http_response.headers.each do |key, value|
            response_headers[key] = value
          end
        end

        @app.call env
      end
    end
  end
end
