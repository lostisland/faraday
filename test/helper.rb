require 'rubygems'
require 'context'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'faraday'

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = 'http://localhost:4567'

    class TestConnection < Faraday::Connection
      class Stubs
        def initialize
          # {:get => [Stub, Stub]}
          @stack = {}
          yield self if block_given?
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
          return true  if request_headers.empty?
          request_headers.each do |key, value|
            return true if headers[key] == value
          end 
          false
        end
      end

      attr_reader :stub

      # TestConnection.new do |expect|
      #   expect.get("/foo/bar", 'Content-Type' => 'application/json') { [200, {'content-type' => 'application/json'}, %(['a','b','c'])] }
      # end
      def initialize(url = nil)
        super(url)
        @stub = Stubs.new do |stubs|
          yield stubs if block_given?
        end
      end

      def _get(uri, headers)
        if stub = @stub.match(:get, uri.path, headers)
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
