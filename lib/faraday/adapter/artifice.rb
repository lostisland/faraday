require 'rack'

module Faraday
  class Adapter
    # This adapter acts much like Yehudas artifice gem, allowing you to
    # forcefully dispatch all requests to a rack endpoint.
    #
    # Faraday.artifice.activate_with(rack_app) do
    #   Faraday.new(:url => 'https://graph.facebook.com').get('/btaylor')
    # end
    class Artifice < Faraday::Adapter
      def self.endpoint=(endpoint)
        Thread.current[:faraday_artifice_endpoint] = endpoint
      end
      def self.endpoint
        Thread.current[:faraday_artifice_endpoint]
      end

      def call(env)
        super
        mock_req_opts = env[:request_headers]
        mock_req_opts ||= {}
        mock_req_opts.merge!(
          :method => env[:method],
          :input => env[:body]
        )
        host_key = mock_req_opts.keys.grep(/^http_host$/i).first || 'HTTP_HOST'
        mock_req_opts[host_key] ||= env[:url].host
        if env[:url].host || env[:url].port
          name_key = mock_req_opts.keys.grep(/^server_name$/i).first || 'SERVER_NAME'
          mock_req_opts[name_key] ||= "#{env[:url].host}:#{env[:url].port}"
        end
        port_key = mock_req_opts.keys.grep(/^server_port$/i).first || 'SERVER_PORT'
        mock_req_opts[port_key] ||= env[:url].port || "80"
        rack_env = Rack::MockRequest.env_for(env[:url].to_s, mock_req_opts)
        status, headers, body = self.class.endpoint.call(rack_env)
        flat_body = ""
        body.each do |chunk|
          flat_body << chunk
        end
        save_response(env, status, flat_body, headers)
        @app.call env
      end
    end
  end
end