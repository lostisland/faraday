require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

if Faraday::Adapter::Typhoeus.loaded?
  class TyphoeusTest < Faraday::TestCase
    describe "#parse_response_headers" do
      before do
        @conn = Object.new.extend(Faraday::Adapter::Typhoeus)
      end

      it "leaves http status line out" do
        headers = @conn.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
        assert_equal %w(content-type), headers.keys
      end

      it "parses lower-cased header name and value" do
        headers = @conn.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
        assert_equal 'text/html', headers['content-type']
      end

      it "parses lower-cased header name and value with colon" do
        headers = @conn.parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://sushi.com/\r\n\r\n")
        assert_equal 'http://sushi.com/', headers['location']
      end
    end
  end
end