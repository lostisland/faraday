require File.expand_path('../../helper', __FILE__)

class RackBuilderEnvTest < Faraday::TestCase
  def setup
    @conn = rack_builder_connection :url => 'http://sushi.com/api',
      :headers => {'Mime-Version' => '1.0'},
      :request => {:oauth => {:consumer_key => 'anonymous'}}

    @conn.options.timeout      = 3
    @conn.options.open_timeout = 5
    @conn.ssl.verify           = false
    @conn.proxy 'http://proxy.com'
  end

  def test_request_create_stores_method
    env = make_env(:get)
    assert_equal :get, env.method
  end

  def test_request_create_stores_uri
    env = make_env do |req|
      req.url 'foo.json', 'a' => 1
    end
    assert_equal 'http://sushi.com/api/foo.json?a=1', env.url.to_s
  end

  def test_request_create_stores_headers
    env = make_env do |req|
      req['Server'] = 'Faraday'
    end
    headers = env.request_headers
    assert_equal '1.0', headers['mime-version']
    assert_equal 'Faraday', headers['server']
  end

  def test_request_create_stores_body
    env = make_env do |req|
      req.body = 'hi'
    end
    assert_equal 'hi', env.body
  end

  def test_global_request_options
    env = make_env
    assert_equal 3, env.request.timeout
    assert_equal 5, env.request.open_timeout
  end

  def test_per_request_options
    env = make_env do |req|
      req.options.timeout = 10
      req.options.boundary = 'boo'
      req.options.oauth[:consumer_secret] = 'xyz'
    end
    assert_equal 10, env.request.timeout
    assert_equal 5, env.request.open_timeout
    assert_equal 'boo', env.request.boundary

    oauth_expected = {:consumer_secret => 'xyz', :consumer_key => 'anonymous'}
    assert_equal oauth_expected, env.request.oauth
  end

  def test_request_create_stores_ssl_options
    env = make_env
    assert_equal false, env.ssl.verify
  end

  def test_request_create_stores_proxy_options
    env = make_env
    assert_equal 'proxy.com', env.request.proxy.host
  end

  private

  def make_env(method = :get, connection = @conn, &block)
    request = connection.build_request(method, &block)
    request.to_env(connection)
  end
end

class RackBuilderResponseTest < Faraday::TestCase
  def setup
    @env = Faraday::Env.from \
      :status => 404, :body => 'yikes',
      :response_headers => {'Content-Type' => 'text/plain'}
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
    @response.finish @env.merge(:params => 'moo')

    loaded = Marshal.load Marshal.dump(@response)
    assert_nil loaded.env[:params]
    assert_equal %w[body response_headers status], loaded.env.keys.map { |k| k.to_s }.sort
  end

  def test_hash
    hash = @response.to_hash
    assert_kind_of Hash, hash
    assert_equal @env.to_hash, hash
  end
end

