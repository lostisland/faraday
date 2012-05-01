module Faraday
  class Adapter
    class Hatetepe < Faraday::Adapter
      dependency "hatetepe/client"
      
      def call(env)
        shutdown = !EM.reactor_running?
        EM.synchrony do
          client, request = client_for(env), request_for(env)

          client << request
          if response = EM::Synchrony.sync(request)
            respond(env, response)
          else
            raise_error(client)
          end

          client.stop
          EM.stop if shutdown
        end

        @app.call(env)
      end

      def client_for(env)
        options = {
          host:            env[:url].host,
          port:            env[:url].port,
          timeout:         env[:request][:timeout],
          connect_timeout: env[:request][:open_timeout]
        }

        ::Hatetepe::Client.start(options)
      end

      def request_for(env)
        verb, uri, headers = env.values_at(:method, :url, :request_headers)

        body = env[:body]
        body = body.read if body.respond_to?(:read)

        ::Hatetepe::Request.new(verb, uri.request_uri, headers, Array(body))
      end

      def respond(env, response)
        save_response(env, response.status, response.body.read) do |headers|
          response.headers.each { |k, v| headers[k] = v }
        end
      end

      def raise_error(client)
        if client.closed_by_timeout?
          raise Faraday::Error::TimeoutError.new("request timed out")
        else
          raise Faraday::Error::ClientError.new("request failed")
        end
      end
    end
  end
end
