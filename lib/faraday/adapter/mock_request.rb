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

        def match(request_method, path, data, request_headers)
          return false if !@stack.key?(request_method)
          stub = @stack[request_method].detect { |stub| stub.matches?(path, data, request_headers) }
          @stack[request_method].delete(stub) if stub
        end

        def get(path, request_headers = {}, &block)
          (@stack[:get] ||= []) << new_stub(path, {}, request_headers, block)
        end

        def delete(path, request_headers = {}, &block)
          (@stack[:delete] ||= []) << new_stub(path, {}, request_headers, block)
        end

        def post(path, data, request_headers = {}, &block)
          (@stack[:post] ||= []) << new_stub(path, data, request_headers, block)
        end

        def put(path, data, request_headers = {}, &block)
          (@stack[:put] ||= []) << new_stub(path, data, request_headers, block)
        end

        def new_stub(path, data, request_headers, block)
          status, response_headers, body = block.call
          Stub.new(path, request_headers, status, response_headers, body, data)
        end
      end

      class Stub < Struct.new(:path, :request_headers, :status, :response_headers, :body, :data)
        def matches?(request_path, params, headers)
          return false if request_path != path
          return false if params != data
          return true  if request_headers.empty?
          request_headers.each do |key, value|
            return false if headers[key] != value
          end 
          true
        end
      end

      def initialize &block
        super
        yield stubs
      end

      def stubs
        @stubs ||= Stubs.new
      end

      def _get(uri, headers)
        raise ConnectionFailed, "no stubbed requests" if stubs.empty?
        if stub = @stubs.match(:get, uri.path, {}, headers)
          response_class.new do |resp|
            resp.headers = stub.response_headers
            resp.process stub.body
          end
        else
          nil
        end
      end

      def _delete(uri, headers)
        raise ConnectionFailed, "no stubbed requests" if stubs.empty?
        if stub = @stubs.match(:delete, uri.path, {}, headers)
          response_class.new do |resp|
            resp.headers = stub.response_headers
            resp.process stub.body
          end
        else
          nil
        end
      end
      def _post(uri, data, headers)
        raise ConnectionFailed, "no stubbed requests" if stubs.empty?
        if stub = @stubs.match(:post, uri.path, data, headers)
          response_class.new do |resp|
            resp.headers = stub.response_headers
            resp.process stub.body
          end
        else
          nil
        end
      end
      def _put(uri, data, headers)
        raise ConnectionFailed, "no stubbed requests" if stubs.empty?
        if stub = @stubs.match(:put, uri.path, data, headers)
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
