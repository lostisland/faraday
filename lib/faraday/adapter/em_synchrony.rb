require 'uri'

module Faraday
  class Adapter
    class EMSynchrony < Faraday::Adapter

      dependency do
        require 'em-synchrony/em-http'
        require 'em-synchrony/em-multi'
        require 'fiber'
      end

      self.supports_parallel = true

      def self.setup_parallel_manager(options = {})
        ParallelManager.new
      end

      def call(env)
        super
        request = EventMachine::HttpRequest.new(URI::parse(env[:url].to_s))
        options = {:head => env[:request_headers]}
        options[:ssl] = env[:ssl] if env[:ssl]

        if env[:body]
          if env[:body].respond_to? :read
            options[:body] = env[:body].read
          else
            options[:body] = env[:body]
          end
        end

        if req = env[:request]
          if proxy = req[:proxy]
            uri = URI.parse(proxy[:uri])
            options[:proxy] = {
              :host => uri.host,
              :port => uri.port
            }
            if proxy[:user] && proxy[:password]
              options[:proxy][:authorization] = [proxy[:user], proxy[:password]]
            end
          end

          # only one timeout currently supported by em http request
          if req[:timeout] or req[:open_timeout]
            options[:timeout] = [req[:timeout] || 0, req[:open_timeout] || 0].max
          end
        end

        http_method = env[:method].to_s.downcase.to_sym

        # Queue requests for parallel execution.
        if env[:parallel_manager]
          env[:parallel_manager].add(request, http_method, options) do |resp|
            save_response(env, resp.response_header.status, resp.response) do |resp_headers|
              resp.response_header.each do |name, value|
                resp_headers[name.to_sym] = value
              end
            end

            # Finalize the response object with values from `env`.
            env[:response].finish(env)
          end

        # Execute single request.
        else
          client = nil
          block = lambda { request.send(http_method, options) }

          if !EM.reactor_running?
            EM.run do
              Fiber.new {
                client = block.call
                EM.stop
              }.resume
            end
          else
            client = block.call
          end

          save_response(env, client.response_header.status, client.response) do |resp_headers|
            client.response_header.each do |name, value|
              resp_headers[name.to_sym] = value
            end
          end
        end

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, $!
      end
    end
  end
end

require 'faraday/adapter/em_synchrony/parallel_manager'

# add missing patch(), options() methods
EventMachine::HTTPMethods.module_eval do
  ([:patch, :options] - instance_methods).each do |type|
    module_eval %[
      def #{type}(options = {}, &blk)
        f = Fiber.current
        conn = setup_request(:#{type}, options, &blk)
        if conn.error.nil?
          conn.callback { f.resume(conn) }
          conn.errback  { f.resume(conn) }
          Fiber.yield
        else
          conn
        end
      end
    ]
  end
end
