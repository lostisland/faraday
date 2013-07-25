require 'uri'

module Faraday
  class Adapter
    class EMSynchrony < Faraday::Adapter
      include EMHttp::Options

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
        request = EventMachine::HttpRequest.new(URI::parse(env[:url].to_s), connection_config(env))        #   end

        http_method = env[:method].to_s.downcase.to_sym

        # Queue requests for parallel execution.
        if env[:parallel_manager]
          env[:parallel_manager].add(request, http_method, request_config(env)) do |resp|
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
          block = lambda { request.send(http_method, request_config(env)) }

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

          raise client.error if client.error

          save_response(env, client.response_header.status, client.response) do |resp_headers|
            client.response_header.each do |name, value|
              resp_headers[name.to_sym] = value
            end
          end
        end

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, $!
      rescue EventMachine::Connectify::CONNECTError => err
        if err.message.include?("Proxy Authentication Required")
          raise Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
        else
          raise Error::ConnectionFailed, err
        end
      end
    end
  end
end

require 'faraday/adapter/em_synchrony/parallel_manager'

# add missing patch(), options() methods
EventMachine::HTTPMethods.module_eval do
  [:patch, :options].each do |type|
    next if method_defined? :"a#{type}"
    alias_method :"a#{type}", type if method_defined? type
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
