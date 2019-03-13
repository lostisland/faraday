# frozen_string_literal: true

module Faraday
  class Adapter
    # Extends Net::HTTP adapter adding methods to perform the request.
    class NetHttp < Faraday::Adapter
      private

      def perform_request(http, env)
        if env[:request].stream_response?
          size = 0
          yielded = false
          http_response = request_with_wrapped_block(http, env) do |chunk|
            if chunk.bytesize.positive? || size.positive?
              yielded = true
              size += chunk.bytesize
              env[:request].on_data.call(chunk, size)
            end
          end
          env[:request].on_data.call('', 0) unless yielded
          # Net::HTTP returns something,
          # but it's not meaningful according to the docs.
          http_response.body = nil
          http_response
        else
          request_with_wrapped_block(http, env)
        end
      end

      def request_with_wrapped_block(http, env, &block)
        if (env[:method] == :get) && !env[:body]
          # prefer `get` to `request` because the former handles gzip (ruby 1.9)
          request_via_get_method(http, env, &block)
        else
          request_via_request_method(http, env, &block)
        end
      end

      def request_via_get_method(http, env, &block)
        http.get env[:url].request_uri, env[:request_headers], &block
      end

      def request_via_request_method(http, env, &block)
        if block_given?
          http.request create_request(env) do |response|
            response.read_body(&block)
          end
        else
          http.request create_request(env)
        end
      end

      def create_request(env)
        request = Net::HTTPGenericRequest.new \
          env[:method].to_s.upcase, # request method
          !!env[:body], # is there request body
          env[:method] != :head, # is there response body
          env[:url].request_uri, # request uri path
          env[:request_headers] # request headers

        if env[:body].respond_to?(:read)
          request.body_stream = env[:body]
        else
          request.body = env[:body]
        end
        request
      end
    end
  end
end
