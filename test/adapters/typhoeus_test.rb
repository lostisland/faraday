require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

if Faraday::Adapter::Typhoeus.loaded?
  module Adapters
    class TestTyphoeus < Faraday::TestCase
      describe "#parse_response_headers" do
        before do
          @adapter = Faraday::Adapter::Typhoeus.new
        end
      
        it "leaves http status line out" do
          headers = @adapter.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
          assert_equal %w(content-type), headers.keys
        end
      
        it "parses lower-cased header name and value" do
          headers = @adapter.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
          assert_equal 'text/html', headers['content-type']
        end
      
        it "parses lower-cased header name and value with colon" do
          headers = @adapter.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://sushi.com/\r\n\r\n")
          assert_equal 'http://sushi.com/', headers['location']
        end
      end
    end
  end
end