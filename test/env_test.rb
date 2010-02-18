require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestEnv < Faraday::TestCase
  def setup
    @conn = Faraday::Connection.new :url => 'http://sushi.com/api', :headers => {'Mime-Version' => '1.0'}
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

  def test_request_create_stores_method
    assert_equal :get, @env[:method]
  end

  def test_request_create_stores_addressable_uri
    assert_equal 'http://sushi.com/api/foo.json?a=1', @env[:url].to_s
  end

  def test_request_create_stores_headers
    assert_kind_of Rack::Utils::HeaderHash, @env[:request_headers]
    assert_equal @input[:headers].merge('Mime-Version' => '1.0'), @env[:request_headers]
  end

  def test_request_create_stores_body
    assert_equal @input[:body], @env[:body]
  end
end