module Faraday
  module Adapter
    module MockRequest
      extend Faraday::Connection::Options
      def self.loaded?() false end

      include Faraday::Error # ConnectionFailed

      class Stubs
        def initialize
          # {:get => [Stub, Stub]}
          @stack = {}
          yield self if block_given?
        end

        def empty?
          @stack.empty?
        end

        def match(request_method, path, request_headers)
          return false if !@stack.key?(request_method)
          @stack[request_method].detect { |stub| stub.matches?(path, request_headers) }
        end

        def get(path, request_headers = {}, &block)
          (@stack[:get] ||= []) << new_stub(path, request_headers, block)
        end

        def new_stub(path, request_headers, block)
          status, response_headers, body = block.call
          Stub.new(path, request_headers, status, response_headers, body)
        end
      end

      class Stub < Struct.new(:path, :request_headers, :status, :response_headers, :body)
        def matches?(request_path, headers)
          return false if request_path != path
          request_headers.each do |key, value|
            return false if headers[key] != value
          end
          true
        end
      end

      def initialize &block
        super nil
        configure(&block) if block
      end

      def configure
        yield stubs
      end

      def stubs
        @stubs ||= Stubs.new
      end

      def _get(uri, headers)
        raise ConnectionFailed, "no stubbed requests" if stubs.empty?
        if stub = @stubs.match(:get, uri.path, headers)
          response_class.new do |resp|
            resp.headers = stub.response_headers
            resp.process stub.body
          end
        else
          nil
        end
      end
    end
  end
end
