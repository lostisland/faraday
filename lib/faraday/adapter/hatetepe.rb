module Faraday
  class Adapter
    class Hatetepe < Faraday::Adapter
      dependency "hatetepe/client"

      self.supports_parallel = true

      def self.setup_parallel_manager(options = nil)
        ParallelManager.new
      end

      class ParallelManager
        def initialize
          reset
        end

        def add
          if running?
            perform_request
          else
            @pending << Proc.new
          end
        end

        def run
          @running = true
          with_reactor do
            perform_request(&@pending.shift) until @pending.empty?
            wait
          end
        ensure
          reset
        end

        def running?
          @running
        end

        private

        def reset
          @pending  = []
          @requests = []
          @running  = false
        end

        def perform_request
          @requests << yield
        end

        def wait
          EM::Synchrony.sync(@requests.shift) until @requests.empty?
        end

        def with_reactor
          stop = !EM.reactor_running?
          EM.synchrony do
            yield
            EM.stop if stop
          end
        end
      end

      def call(env)
        super

        manager = env[:parallel_manager] || ParallelManager.new
        manager.add { perform_request(env, request_for(env)) }

        unless env[:parallel_manager]
          env[:parallel_manager] = true
          manager.run
        end

        @app.call(env).tap { env[:response].finish(env) }
      end

      def perform_request(env, request)
        client = client_for(env)
        client << request

        request.callback {|response| respond(env, response) }
        request.errback do |response|
          response ? respond(env, response) : raise_error(client)
        end
      end

      def client_for(env)
        options = {
          :host            => env[:url].host,
          :port            => env[:url].port,
          :timeout         => env[:request][:timeout],
          :connect_timeout => env[:request][:open_timeout]
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
