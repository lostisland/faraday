require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseTest < Faraday::TestCase
  describe "TestConnection#get with default Faraday::Response class" do
    it "returns Faraday::Response" do
      conn = TestConnection.new do |stub|
        stub.get('/hello') { [200, {}, 'hello world']}
      end
      resp = conn.get('/hello')
      assert_equal 'hello world', resp.body
    end
  end

  describe "TestConnection#get with Faraday::StringResponse class" do
    it "returns string body" do
      conn = TestConnection.new do |stub|
        stub.get('/hello') { [200, {}, 'hello world']}
      end
      conn.response_class = Faraday::Response::StringResponse
      assert_equal 'hello world', conn.get('/hello')
    end
  end

  describe "TestConnection#get with Faraday::YajlResponse class" do
    it "returns string body" do
      conn = TestConnection.new do |stub|
        stub.get('/hello') { [200, {}, '[1,2,3]']}
      end
      conn.response_class = Faraday::Response::YajlResponse
      assert_equal [1,2,3], conn.get('/hello')
    end
  end
end