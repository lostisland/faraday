
module Faraday
  class Adapter
    class Faraday::Adapter::Vertx < Faraday::Adapter

      dependency 'vertx'

      def call(environment)
        super
        perform_request environment
        @app.call environment
      end

      private

      def perform_request(environment)
        method, url, body = *environment.values_at(:method, :url, :body)
        client = ::Vertx::HttpClient.new
        client.host, client.port = url.host, url.port
        environment[:parallel_manager] = true
        request = client.request method.to_s.upcase, url.path do |response|
          response.body_handler do |body|
            save_response environment, response.status_code, body.to_s, response.headers
            environment[:response].finish environment unless environment[:response].finished?
          end
        end
        request.headers.merge! environment[:request_headers] || { }
        if body
          request.headers["Content-Length"] = body.bytesize
          request.write_str body
        end
        request.end
      end

    end
  end
end
