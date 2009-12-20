require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseTest < Faraday::TestCase
  describe "unloaded response class" do
    it "is not allowed to be set" do
      resp_class = Object.new
      def resp_class.loaded?() false end
      conn = Faraday::Connection.new
      assert_raises ArgumentError do
        conn.response_class = resp_class
      end
    end
  end

  describe "TestConnection#get with default Faraday::Response class" do
    it "returns Faraday::Response" do
      conn = Faraday::TestConnection.new do |stub|
        stub.get('/hello') { [200, {}, 'hello world']}
      end
      resp = conn.get('/hello')
      assert_equal 'hello world', resp.body
    end
  end

  describe "TestConnection#get with Faraday::YajlResponse class" do
    it "returns string body" do
      conn = Faraday::TestConnection.new do |stub|
        stub.get('/hello') { [200, {}, '[1,2,3]']}
      end
      conn.response_class = Faraday::Response::YajlResponse
      assert_equal [1,2,3], conn.get('/hello').body
    end
  end
end
