# frozen_string_literal: true

require 'uri'

module Faraday
  class Adapter
    # EventMachine Synchrony adapter.
    class EMSynchrony < Faraday::Adapter
      include EMHttp::Options

      dependency do
        require 'em-synchrony/em-http'
        require 'em-synchrony/em-multi'
        require 'fiber'
      end

      self.supports_parallel = true

      # @return [ParallelManager]
      def self.setup_parallel_manager(_options = nil)
        ParallelManager.new
      end

      def call(env)
        super
        request = create_request(env)

        http_method = env[:method].to_s.downcase.to_sym

        # Queue requests for parallel execution.
        if env[:parallel_manager]
          env[:parallel_manager].add(request, http_method, request_config(env)) do |resp|
            if (req = env[:request]).stream_response?
              warn "Streaming downloads for #{self.class.name} are not yet implemented."
              req.on_data.call(resp.response, resp.response.bytesize)
            end

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
          block = -> { request.send(http_method, request_config(env)) }

          if !EM.reactor_running?
            EM.run do
              Fiber.new do
                client = block.call
                EM.stop
              end.resume
            end
          else
            client = block.call
          end

          raise client.error if client.error

          if env[:request].stream_response?
            warn "Streaming downloads for #{self.class.name} are not yet implemented."
            env[:request].on_data.call(client.response, client.response.bytesize)
          end
          status = client.response_header.status
          reason = client.response_header.http_reason
          save_response(env, status, client.response, nil, reason) do |resp_headers|
            client.response_header.each do |name, value|
              resp_headers[name.to_sym] = value
            end
          end
        end

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Faraday::ConnectionFailed, $ERROR_INFO
      rescue EventMachine::Connectify::CONNECTError => err
        raise Faraday::ConnectionFailed, %(407 "Proxy Authentication Required ") if err.message.include?('Proxy Authentication Required')

        raise Faraday::ConnectionFailed, err
      rescue Errno::ETIMEDOUT => err
        raise Faraday::TimeoutError, err
      rescue RuntimeError => err
        raise Faraday::ConnectionFailed, err if err.message == 'connection closed by server'

        raise
      rescue StandardError => err
        raise Faraday::SSLError, err if defined?(OpenSSL) && err.is_a?(OpenSSL::SSL::SSLError)

        raise
      end

      def create_request(env)
        EventMachine::HttpRequest.new(Utils::URI(env[:url].to_s), connection_config(env).merge(@connection_options))
      end
    end
  end
end

require 'faraday/adapter/em_synchrony/parallel_manager'

if Faraday::Adapter::EMSynchrony.loaded?
  begin
    require 'openssl'
  rescue LoadError
    warn 'Warning: no such file to load -- openssl. Make sure it is installed if you want HTTPS support'
  else
    require 'faraday/adapter/em_http_ssl_patch'
  end
end
