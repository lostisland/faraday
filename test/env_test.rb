require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestEnv < Faraday::TestCase
  describe "Request#create" do
    before :all do
      @conn = Faraday::Connection.new :url => 'http://sushi.com/api'
      @input = {
        :body    => 'abc',
        :headers => {'Server' => 'Faraday'}}
      @env_setup = Faraday::Request.create do |req|
        req.url 'foo.json', 'a' => 1
        req['Server'] = 'Faraday'
        req.body = @input[:body]
      end
      @env  = @env_setup.to_env_hash(@conn, :get)
    end

    it "stores method in :method" do
      assert_equal :get, @env[:method]
    end

    it "stores Addressable::URI in :url" do
      assert_equal 'http://sushi.com/api/foo.json?a=1', @env[:url].to_s
    end

    it "stores headers in :headers" do
      assert_kind_of Rack::Utils::HeaderHash, @env[:request_headers]
      assert_equal @input[:headers], @env[:request_headers]
    end

    it "stores body in :body" do
      assert_equal @input[:body], @env[:body]
    end
  end
end