require 'http_client'

module Faraday
  class Adapter
    class ApacheClient < Faraday::Adapter
      def call(env)
        super
        
        req  = env[:request]
        args = [ env[:url] ]
        env[:client_options] ||= {}
        
        # The Java client sets this.  Setting it twice generates an error
        env[:request_headers].delete('Content-Length')
        
        http = HTTP::Client.new env[:url], env[:client_options]
        http.timeout_in_seconds = req[:timeout]    if req[:timeout]
        http.default_proxy      = req[:proxy].to_s if req[:proxy]
        http.connection_timeout = req[:open_timeout] * 1000 if req[:open_timeout]
        
        # TODO: support streaming requests
        env[:body] = env[:body].read if env[:body].respond_to? :read
        
        request = HTTP.const_get(env[:method].to_s.capitalize).new(*args)
        
        # For some reason Apache HTTP-Client doesn't support a
        #   body in an OPTIONS request and doesn't support PATCH at all
        request.body = env[:body] if [:post, :put].include?(env[:method])
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

        save_response(env, http_response.status_code, http_response.body, http_response.headers.to_hash)

        @app.call env
      end
    end
  end
end
