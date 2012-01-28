require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class EnvTest < Faraday::TestCase
  def setup
    @conn = Faraday.new :url => 'http://sushi.com/api',
      :headers => {'Mime-Version' => '1.0'},
      :request => {:oauth => {:consumer_key => 'anonymous'}}

    @conn.options[:timeout]      = 3
    @conn.options[:open_timeout] = 5
    @conn.ssl[:verify]           = false
    @conn.proxy 'http://proxy.com'
  end

  def test_request_create_stores_method
    env = make_env(:get)
    assert_equal :get, env[:method]
  end

  def test_request_create_stores_uri
    env = make_env do |req|
      req.url 'foo.json', 'a' => 1
    end
    assert_equal 'http://sushi.com/api/foo.json?a=1', env[:url].to_s
  end

  def test_request_create_stores_headers
    env = make_env do |req|
      req['Server'] = 'Faraday'
    end
    headers = env[:request_headers]
    assert_equal '1.0', headers['mime-version']
    assert_equal 'Faraday', headers['server']
  end

  def test_request_create_stores_body
    env = make_env do |req|
      req.body = 'hi'
    end
    assert_equal 'hi', env[:body]
  end

  def test_global_request_options
    env = make_env
    assert_equal 3, env[:request][:timeout]
    assert_equal 5, env[:request][:open_timeout]
  end

  def test_per_request_options
    env = make_env do |req|
      req.options[:timeout] = 10
      req.options[:custom] = true
      req.options[:oauth][:consumer_secret] = 'xyz'
    end
    assert_equal 10, env[:request][:timeout]
    assert_equal 5, env[:request][:open_timeout]
    assert_equal true, env[:request][:custom]

    oauth_expected = {:consumer_secret => 'xyz', :consumer_key => 'anonymous'}
    assert_equal oauth_expected, env[:request][:oauth]
  end

  def test_request_create_stores_ssl_options
    env = make_env
    assert_equal false, env[:ssl][:verify]
  end

  def test_request_create_stores_proxy_options
    env = make_env
    assert_equal 'proxy.com', env[:request][:proxy][:uri].host
  end

  private

  def make_env(method = :get, connection = @conn, &block)
    request = connection.build_request(method, &block)
    request.to_env(connection)
  end
end

class HeadersTest < Faraday::TestCase
  def setup
    @headers = Faraday::Utils::Headers.new
  end

  def test_normalizes_different_capitalizations
    @headers['Content-Type'] = 'application/json'
    assert_equal ['Content-Type'], @headers.keys
    assert_equal 'application/json', @headers['Content-Type']
    assert_equal 'application/json', @headers['CONTENT-TYPE']
    assert_equal 'application/json', @headers['content-type']
    assert @headers.include?('content-type')

    @headers['content-type'] = 'application/xml'
    assert_equal ['Content-Type'], @headers.keys
    assert_equal 'application/xml', @headers['Content-Type']
    assert_equal 'application/xml', @headers['CONTENT-TYPE']
    assert_equal 'application/xml', @headers['content-type']
  end

  def test_delete_key
    @headers['Content-Type'] = 'application/json'
    assert_equal 1, @headers.size
    assert @headers.include?('content-type')
    assert_equal 'application/json', @headers.delete('content-type')
    assert_equal 0, @headers.size
    assert !@headers.include?('content-type')
    assert_equal nil, @headers.delete('content-type')
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

class ResponseTest < Faraday::TestCase
  def setup
    @env = {
      :status => 404, :body => 'yikes',
      :response_headers => Faraday::Utils::Headers.new('Content-Type' => 'text/plain')
    }
    @response = Faraday::Response.new @env
  end

  def test_finished
    assert @response.finished?
  end

  def test_error_on_finish
    assert_raises RuntimeError do
      @response.finish({})
    end
  end

  def test_not_success
    assert !@response.success?
  end

  def test_status
    assert_equal 404, @response.status
  end

  def test_body
    assert_equal 'yikes', @response.body
  end

  def test_headers
    assert_equal 'text/plain', @response.headers['Content-Type']
    assert_equal 'text/plain', @response['content-type']
  end

  def test_apply_request
    @response.apply_request :body => 'a=b', :method => :post
    assert_equal 'yikes', @response.body
    assert_equal :post, @response.env[:method]
  end

  def test_marshal
    @response = Faraday::Response.new
    @response.on_complete { }
    @response.finish @env.merge(:custom => 'moo')

    loaded = Marshal.load Marshal.dump(@response)
    assert_nil loaded.env[:custom]
    assert_equal %w[body response_headers status], loaded.env.keys.map { |k| k.to_s }.sort
  end
end
