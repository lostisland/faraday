require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class EnvTest < Faraday::TestCase
  def setup
    @conn = Faraday.new :url => 'http://sushi.com/api', :headers => {'Mime-Version' => '1.0'}
    @conn.options[:timeout]      = 3
    @conn.options[:open_timeout] = 5
    @conn.ssl[:verify]           = false
    @conn.proxy 'http://proxy.com'
    @input = { :body => 'abc' }
    @env = env_for @conn do |req|
      req.url 'foo.json', 'a' => 1
      req['Server'] = 'Faraday'
      req.body = @input[:body]
    end
  end

  def test_request_create_stores_method
    assert_equal :get, @env[:method]
  end

  def test_request_create_stores_addressable_uri
    assert_equal 'http://sushi.com/api/foo.json?a=1', @env[:url].to_s
  end

  def test_request_create_stores_headers
    headers = @env[:request_headers]
    assert_equal '1.0', headers['mime-version']
    assert_equal 'Faraday', headers['server']
  end

  def test_request_create_stores_body
    assert_equal @input[:body], @env[:body]
  end

  def test_request_create_stores_timeout_options
    assert_equal 3, @env[:request][:timeout]
    assert_equal 5, @env[:request][:open_timeout]
  end

  def test_request_create_stores_ssl_options
    assert_equal false, @env[:ssl][:verify]
  end

  def test_request_create_stores_proxy_options
    assert_equal 'proxy.com', @env[:request][:proxy][:uri].host
  end

  def env_for(connection)
    env_setup = Faraday::Request.create do |req|
      yield req
    end
    env_setup.to_env_hash(connection, :get)
  end
end

class HeadersTest < Faraday::TestCase
  def setup
    @headers = Faraday::Utils::Headers.new
  end

  def test_parse_response_headers_leaves_http_status_line_out
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
    assert_equal %w(Content-Type), @headers.keys
  end

  def test_parse_response_headers_parses_lower_cased_header_name_and_value
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
    assert_equal 'text/html', @headers['content-type']
  end

  def test_parse_response_headers_parses_lower_cased_header_name_and_value_with_colon
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://sushi.com/\r\n\r\n")
    assert_equal 'http://sushi.com/', @headers['location']
  end

  def test_parse_response_headers_parses_blank_lines
    @headers.parse("HTTP/1.1 200 OK\r\n\r\nContent-Type: text/html\r\n\r\n")
    assert_equal 'text/html', @headers['content-type']
  end
end
