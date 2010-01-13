require 'net/http'
module Faraday
  module Adapter
    class NetHttp < Middleware
      def call(env)
        process_body_for_request(env)

        http      = Net::HTTP.new(env[:url].host, env[:url].port)
        full_path = full_path_for(env[:url].path, env[:url].query, env[:url].fragment)
        http_resp = http.send_request(env[:method].to_s.upcase, full_path, env[:body], env[:request_headers])

        resp_headers = {}
        http_resp.each_header do |key, value|
          resp_headers[key] = value
        end

        env.update \
          :status           => http_resp.code.to_i, 
          :response_headers => resp_headers, 
          :body             => http_resp.body

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, "connection refused"
      end
    end
  end
end
