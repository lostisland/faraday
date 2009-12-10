require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

class NetHttpAdapterTest < Faraday::TestCase
  class Connection < Faraday::Connection
    include Faraday::Adapter::NetHttp
  end
  Faraday::Connection.send :include, Faraday::Adapter::NetHttp

  describe "#get" do
    it "retrieves the response body" do
      assert_equal 'hello world', Faraday::Connection.new(LIVE_SERVER).get('hello_world').body
    end

    it "retrieves the response JSON with YajlResponse" do
      conn = Faraday::Connection.new(LIVE_SERVER)
      conn.response_class = Faraday::Response::YajlResponse
      assert_equal [1,2,3], conn.get('json')
    end

    it "retrieves the response headers" do
      assert_equal 'text/html', Faraday::Connection.new(LIVE_SERVER).get('hello_world').headers['content-type']
    end
  end
end