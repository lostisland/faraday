require File.expand_path('../helper', __FILE__)

class TestConnection < Faraday::TestCase
  def teardown
    Faraday.default_connection_options = nil
  end

  def with_test_conn
    old_conn = Faraday.default_connection
    Faraday.default_connection = Faraday::Connection.new do |builder|
      builder.adapter :test do |stub|
        stub.get('/') do |_|
          [200, nil, nil]
        end
      end
    end

    begin
      yield
    ensure
      Faraday.default_connection = old_conn
    end
  end

  def with_env_proxy_disabled
    Faraday.ignore_env_proxy = true

    begin
      yield
    ensure
      Faraday.ignore_env_proxy = false
    end
  end




  def test_request_header_change_does_not_modify_connection_header
    connection = Faraday.new(:url => 'https://asushi.com/sake.html')
    connection.headers = {'Authorization' => 'token abc123'}

    request = connection.build_request(:get)
    request.headers.delete('Authorization')

    assert_equal connection.headers.keys.sort, ['Authorization']
    assert connection.headers.include?('Authorization')

    assert_equal request.headers.keys.sort, []
    assert !request.headers.include?('Authorization')
  end



  def test_ignore_env_proxy
    with_env_proxy_disabled do
      with_env 'http_proxy' => 'http://duncan.proxy.com:80' do
        conn = Faraday::Connection.new(proxy: nil)
        assert_nil conn.proxy
      end
    end
  end


  def test_dups_connection_object
    conn = Faraday::Connection.new 'http://sushi.com/foo',
      :ssl => { :verify => :none },
      :headers => {'content-type' => 'text/plain'},
      :params => {'a'=>'1'},
      :request => {:timeout => 5}

    other = conn.dup

    assert_equal conn.build_exclusive_url, other.build_exclusive_url
    assert_equal 'text/plain', other.headers['content-type']
    assert_equal '1', other.params['a']

    other.basic_auth('', '')
    other.headers['content-length'] = 12
    other.params['b'] = '2'
    other.options[:open_timeout] = 10

    assert_equal 1, other.builder.handlers.size
    assert_equal 1, conn.builder.handlers.size
    assert !conn.headers.key?('content-length')
    assert !conn.params.key?('b')
    assert_equal 5, other.options[:timeout]
    assert_nil conn.options[:open_timeout]
  end

  def test_initialize_with_false_option
    conn = Faraday::Connection.new :ssl => {:verify => false}
    assert !conn.ssl.verify?
  end

  def test_init_with_block
    conn = Faraday::Connection.new { }
    assert_equal 0, conn.builder.handlers.size
  end

  def test_init_with_block_yields_connection
    conn = Faraday::Connection.new(:params => {'a'=>'1'}) { |faraday|
      faraday.adapter :net_http
      faraday.url_prefix = 'http://sushi.com/omnom'
      assert_equal '1', faraday.params['a']
    }
    assert_equal 0, conn.builder.handlers.size
    assert_equal '/omnom', conn.path_prefix
  end

  def test_respond_to
    assert Faraday.respond_to?(:get)
    assert Faraday.respond_to?(:post)
  end

  def test_default_connection_options
    Faraday.default_connection_options.request.timeout = 10
    conn = Faraday.new 'http://sushi.com/foo'
    assert_equal 10, conn.options.timeout
  end

  def test_default_connection_options_without_url
    Faraday.default_connection_options.request.timeout = 10
    conn = Faraday.new :url => 'http://sushi.com/foo'
    assert_equal 10, conn.options.timeout
  end

  def test_default_connection_options_as_hash
    Faraday.default_connection_options = { request: { timeout: 10 } }
    conn = Faraday.new 'http://sushi.com/foo'
    assert_equal 10, conn.options.timeout
  end

  def test_default_connection_options_as_hash_without_url
    Faraday.default_connection_options = { request: { timeout: 10 } }
    conn = Faraday.new :url => 'http://sushi.com/foo'
    assert_equal 10, conn.options.timeout
  end

  def test_default_connection_options_as_hash_with_instance_connection_options
    Faraday.default_connection_options = { request: { timeout: 10 } }
    conn = Faraday.new 'http://sushi.com/foo', request: { open_timeout: 1 }
    assert_equal 1, conn.options.open_timeout
    assert_equal 10, conn.options.timeout
  end

  def test_default_connection_options_persist_with_an_instance_overriding
    Faraday.default_connection_options.request.timeout = 10
    conn = Faraday.new 'http://nigiri.com/bar'
    conn.options.timeout = 1
    assert_equal 10, Faraday.default_connection_options.request.timeout

    other = Faraday.new :url => 'https://sushi.com/foo'
    other.options.timeout = 1

    assert_equal 10, Faraday.default_connection_options.request.timeout
  end

  def test_default_connection_uses_default_connection_options
    Faraday.default_connection_options.request.timeout = 10
    default_conn = Faraday.default_connection

    assert_equal 10, default_conn.options.timeout
  end

  def env_url(url, params)
    conn = Faraday::Connection.new(url, :params => params)
    yield(conn) if block_given?
    req = conn.build_request(:get)
    req.to_env(conn).url
  end
end

class TestRequestParams < Faraday::TestCase
  def create_connection(*args)
    @conn = Faraday::Connection.new(*args) do |conn|
      yield(conn) if block_given?
      class << conn.builder
        undef app
        def app() lambda { |env| env } end
      end
    end
  end

  def assert_query_equal(expected, query)
    assert_equal expected, query.split('&').sort
  end

  def with_default_params_encoder(encoder)
    old_encoder = Faraday::Utils.default_params_encoder
    begin
      Faraday::Utils.default_params_encoder = encoder
      yield
    ensure
      Faraday::Utils.default_params_encoder = old_encoder
    end
  end

  def test_merges_connection_and_request_params
    create_connection 'http://a.co/?token=abc', :params => {'format' => 'json'}
    query = get '?page=1', :limit => 5
    assert_query_equal %w[format=json limit=5 page=1 token=abc], query
  end

  def test_overrides_connection_params
    create_connection 'http://a.co/?a=a&b=b&c=c', :params => {:a => 'A'} do |conn|
      conn.params[:b] = 'B'
      assert_equal 'c', conn.params[:c]
    end
    assert_query_equal %w[a=A b=B c=c], get
  end

  def test_all_overrides_connection_params
    create_connection 'http://a.co/?a=a', :params => {:c => 'c'} do |conn|
      conn.params = {'b' => 'b'}
    end
    assert_query_equal %w[b=b], get
  end

  def test_overrides_request_params
    create_connection
    query = get '?p=1&a=a', :p => 2
    assert_query_equal %w[a=a p=2], query
  end

  def test_overrides_request_params_block
    create_connection
    query = get '?p=1&a=a', :p => 2 do |req|
      req.params[:p] = 3
    end
    assert_query_equal %w[a=a p=3], query
  end

  def test_overrides_request_params_block_url
    create_connection
    query = get nil, :p => 2 do |req|
      req.url '?p=1&a=a', 'p' => 3
    end
    assert_query_equal %w[a=a p=3], query
  end

  def test_overrides_all_request_params
    create_connection :params => {:c => 'c'}
    query = get '?p=1&a=a', :p => 2 do |req|
      assert_equal 'a', req.params[:a]
      assert_equal 'c', req.params['c']
      assert_equal 2, req.params['p']
      req.params = {:b => 'b'}
      assert_equal 'b', req.params['b']
    end
    assert_query_equal %w[b=b], query
  end

  def test_array_params_in_url
    with_default_params_encoder(nil) do
      create_connection 'http://a.co/page1?color[]=red&color[]=blue'
      query = get
      assert_equal 'color%5B%5D=red&color%5B%5D=blue', query
    end
  end

  def test_array_params_in_params
    with_default_params_encoder(nil) do
      create_connection 'http://a.co/page1', :params => {:color => ['red', 'blue']}
      query = get
      assert_equal 'color%5B%5D=red&color%5B%5D=blue', query
    end
  end

  def test_array_params_in_url_with_flat_params
    with_default_params_encoder(Faraday::FlatParamsEncoder) do
      create_connection 'http://a.co/page1?color=red&color=blue'
      query = get
      assert_equal 'color=red&color=blue', query
    end
  end

  def test_array_params_in_params_with_flat_params
    with_default_params_encoder(Faraday::FlatParamsEncoder) do
      create_connection 'http://a.co/page1', :params => {:color => ['red', 'blue']}
      query = get
      assert_equal 'color=red&color=blue', query
    end
  end

  def test_params_with_connection_options
    encoder = Object.new
    def encoder.encode(params)
      params.map { |k,v| "#{k.upcase}-#{v.upcase}" }.join(',')
    end

    create_connection :params => {:color => 'red'}
    query = get('', :feeling => 'blue') do |req|
      req.options.params_encoder = encoder
    end
    assert_equal ['COLOR-RED', 'FEELING-BLUE'], query.split(',').sort
  end

  def get(*args)
    env = @conn.get(*args) do |req|
      yield(req) if block_given?
    end
    env[:url].query
  end
end
