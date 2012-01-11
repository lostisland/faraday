require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require 'uri'

class TestConnection < Faraday::TestCase

  def with_proxy_env(proxy)
    old_proxy = ENV['http_proxy']
    ENV['http_proxy'] = proxy
    begin
      yield
    ensure
      ENV['http_proxy'] = old_proxy
    end
  end

  def test_initialize_parses_host_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com"
    assert_equal 'sushi.com', conn.host
  end

  def test_initialize_inherits_default_port_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com"
    assert_equal 80, conn.port
  end

  def test_initialize_parses_scheme_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com"
    assert_equal 'http', conn.scheme
  end

  def test_initialize_parses_port_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com:815"
    assert_equal 815, conn.port
  end

  def test_initialize_parses_nil_path_prefix_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com"
    assert_equal '/', conn.path_prefix
  end

  def test_initialize_parses_path_prefix_out_of_given_url
    conn = Faraday::Connection.new "http://sushi.com/fish"
    assert_equal '/fish', conn.path_prefix
  end

  def test_initialize_parses_path_prefix_out_of_given_url_option
    conn = Faraday::Connection.new :url => "http://sushi.com/fish"
    assert_equal '/fish', conn.path_prefix
  end

  def test_initialize_stores_default_params_from_options
    conn = Faraday::Connection.new :params => {:a => 1}
    assert_equal({'a' => 1}, conn.params)
  end

  def test_initialize_stores_default_params_from_uri
    conn = Faraday::Connection.new "http://sushi.com/fish?a=1"
    assert_equal({'a' => '1'}, conn.params)
  end

  def test_initialize_stores_default_params_from_uri_and_options
    conn = Faraday::Connection.new "http://sushi.com/fish?a=1&b=2", :params => {'a' => 3}
    assert_equal({'a' => 3, 'b' => '2'}, conn.params)
  end

  def test_initialize_stores_default_headers_from_options
    conn = Faraday::Connection.new :headers => {:user_agent => 'Faraday'}
    assert_equal 'Faraday', conn.headers['User-agent']
  end

  def test_basic_auth_prepends_basic_auth_middleware
    conn = Faraday::Connection.new
    conn.basic_auth 'Aladdin', 'open sesame'
    assert_equal Faraday::Request::BasicAuthentication, conn.builder[0].klass
    assert_equal ['Aladdin', 'open sesame'], conn.builder[0].instance_eval { @args }
  end

  def test_auto_parses_basic_auth_from_url_and_unescapes
    conn = Faraday::Connection.new :url => "http://foo%40bar.com:pass%20word@sushi.com/fish"
    assert_equal Faraday::Request::BasicAuthentication, conn.builder[0].klass
    assert_equal ['foo@bar.com', 'pass word'], conn.builder[0].instance_eval { @args }
  end

  def test_token_auth_prepends_token_auth_middleware
    conn = Faraday::Connection.new
    conn.token_auth 'abcdef', :nonce => 'abc'
    assert_equal Faraday::Request::TokenAuthentication, conn.builder[0].klass
    assert_equal ['abcdef', { :nonce => 'abc' }], conn.builder[0].instance_eval { @args }
  end

  def test_build_url_uses_connection_host_as_default_uri_host
    conn = Faraday::Connection.new
    conn.host = 'sushi.com'
    uri = conn.build_url("/sake.html")
    assert_equal 'sushi.com', uri.host
  end

  def test_build_url_overrides_connection_port_for_absolute_urls
    conn = Faraday::Connection.new
    conn.port = 23
    uri = conn.build_url("http://sushi.com")
    assert_equal 80, uri.port
  end

  def test_build_url_uses_connection_scheme_as_default_uri_scheme
    conn = Faraday::Connection.new 'http://sushi.com'
    uri = conn.build_url("/sake.html")
    assert_equal 'http', uri.scheme
  end

  def test_build_url_uses_connection_path_prefix_to_customize_path
    conn = Faraday::Connection.new
    conn.path_prefix = '/fish'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_uses_root_connection_path_prefix_to_customize_path
    conn = Faraday::Connection.new
    conn.path_prefix = '/'
    uri = conn.build_url("sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_forces_connection_path_prefix_to_be_absolute
    conn = Faraday::Connection.new
    conn.path_prefix = 'fish'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_ignores_connection_path_prefix_trailing_slash
    conn = Faraday::Connection.new
    conn.path_prefix = '/fish/'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_allows_absolute_uri_to_ignore_connection_path_prefix
    conn = Faraday::Connection.new
    conn.path_prefix = '/fish'
    uri = conn.build_url("/sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_parses_url_params_into_path
    conn = Faraday::Connection.new
    uri = conn.build_url("http://sushi.com/sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_doesnt_add_ending_slash
    conn = Faraday::Connection.new
    conn.url_prefix = "http://sushi.com/nigiri"
    uri = conn.build_url(nil)
    assert_equal "/nigiri", uri.path
  end

  def test_build_url_parses_url_params_into_query
    conn = Faraday::Connection.new
    uri = conn.build_url("http://sushi.com/sake.html", 'a[b]' => '1 + 2')
    assert_equal "a%5Bb%5D=1+%2B+2", uri.query
  end

  def test_build_url_parses_url
    conn = Faraday::Connection.new
    uri = conn.build_url("http://sushi.com/sake.html")
    assert_equal "http",       uri.scheme
    assert_equal "sushi.com",  uri.host
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_parses_url_and_changes_scheme
    conn = Faraday::Connection.new :url => "http://sushi.com/sushi"
    conn.scheme = 'https'
    uri = conn.build_url("sake.html")
    assert_equal 'https://sushi.com/sushi/sake.html', uri.to_s
  end

  def test_proxy_accepts_string
    with_proxy_env "http://duncan.proxy.com:80" do
      conn = Faraday::Connection.new
      conn.proxy 'http://proxy.com'
      assert_equal 'proxy.com', conn.proxy[:uri].host
      assert_equal [:uri],      conn.proxy.keys
    end
  end

  def test_proxy_accepts_uri
    with_proxy_env "http://duncan.proxy.com:80" do
      conn = Faraday::Connection.new
      conn.proxy URI.parse('http://proxy.com')
      assert_equal 'proxy.com', conn.proxy[:uri].host
      assert_equal [:uri],      conn.proxy.keys
    end
  end

  def test_proxy_accepts_hash_with_string_uri
    with_proxy_env "http://duncan.proxy.com:80" do
      conn = Faraday::Connection.new
      conn.proxy :uri => 'http://proxy.com', :user => 'rick'
      assert_equal 'proxy.com', conn.proxy[:uri].host
      assert_equal 'rick',      conn.proxy[:user]
    end
  end

  def test_proxy_accepts_hash
    with_proxy_env "http://duncan.proxy.com:80" do
      conn = Faraday::Connection.new
      conn.proxy :uri => URI.parse('http://proxy.com'), :user => 'rick'
      assert_equal 'proxy.com', conn.proxy[:uri].host
      assert_equal 'rick',      conn.proxy[:user]
    end
  end

  def test_proxy_accepts_http_env
    with_proxy_env "http://duncan.proxy.com:80" do
      conn = Faraday::Connection.new
      assert_equal 'duncan.proxy.com', conn.proxy[:uri].host
    end
  end

  def test_proxy_requires_uri
    conn = Faraday::Connection.new
    assert_raises ArgumentError do
      conn.proxy :uri => :bad_uri, :user => 'rick'
    end
  end

  def test_params_to_query_converts_hash_of_params_to_uri_escaped_query_string
    conn = Faraday::Connection.new
    url = conn.build_url('', 'a[b]' => '1 + 2')
    assert_equal "a%5Bb%5D=1+%2B+2", url.query
  end

  def test_dups_connection_object
    conn = Faraday::Connection.new 'http://sushi.com/foo',
      :ssl => { :verify => :none },
      :headers => {'content-type' => 'text/plain'},
      :params => {'a'=>'1'}

    other = conn.dup

    assert_equal conn.build_url(''), other.build_url('')
    assert_equal 'text/plain', other.headers['content-type']
    assert_equal '1', other.params['a']

    other.basic_auth('', '')
    other.headers['content-length'] = 12
    other.params['b'] = '2'

    assert_equal 3, other.builder.handlers.size
    assert_equal 2, conn.builder.handlers.size
    assert !conn.headers.key?('content-length')
    assert !conn.params.key?('b')
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
    assert_equal 1, conn.builder.handlers.size
    assert_equal '/omnom', conn.path_prefix
  end
end

class TestRequestParams < Faraday::TestCase
  def create_connection(*args)
    @conn = Faraday::Connection.new(*args) do |conn|
      yield conn if block_given?
      class << conn
        undef app
        def app() lambda { |env| env } end
      end
    end
  end

  def get(*args)
    env = @conn.get(*args) do |req|
      yield req if block_given?
    end
    env[:url].query
  end

  def assert_query_equal(expected, query)
    assert_equal expected, query.split('&').sort
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
end
