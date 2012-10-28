require File.expand_path('../helper', __FILE__)

module ConnectionTests
  def with_env(key, proxy)
    old_value = ENV.fetch(key, false)
    ENV[key] = proxy
    begin
      yield
    ensure
      if old_value == false
        ENV.delete key
      else
        ENV[key] = old_value
      end
    end
  end

  def test_initialize_parses_host_out_of_given_url
    conn = connection("http://sushi.com")
    assert_equal 'sushi.com', conn.host
  end

  def test_initialize_inherits_default_port_out_of_given_url
    conn = connection("http://sushi.com")
    assert_equal 80, conn.port
  end

  def test_initialize_parses_scheme_out_of_given_url
    conn = connection("http://sushi.com")
    assert_equal 'http', conn.scheme
  end

  def test_initialize_parses_port_out_of_given_url
    conn = connection("http://sushi.com:815")
    assert_equal 815, conn.port
  end

  def test_initialize_parses_nil_path_prefix_out_of_given_url
    conn = connection("http://sushi.com")
    assert_equal '/', conn.path_prefix
  end

  def test_initialize_parses_path_prefix_out_of_given_url
    conn = connection("http://sushi.com/fish")
    assert_equal '/fish', conn.path_prefix
  end

  def test_initialize_parses_path_prefix_out_of_given_url_option
    conn = connection :url => "http://sushi.com/fish"
    assert_equal '/fish', conn.path_prefix
  end

  def test_initialize_stores_default_params_from_options
    conn = connection :params => {:a => 1}
    assert_equal({'a' => 1}, conn.params)
  end

  def test_initialize_stores_default_params_from_uri
    conn = connection "http://sushi.com/fish?a=1"
    assert_equal({'a' => '1'}, conn.params)
  end

  def test_initialize_stores_default_params_from_uri_and_options
    conn = connection "http://sushi.com/fish?a=1&b=2", :params => {'a' => 3}
    assert_equal({'a' => 3, 'b' => '2'}, conn.params)
  end

  def test_initialize_stores_default_headers_from_options
    conn = connection :headers => {:user_agent => 'Faraday'}
    assert_equal 'Faraday', conn.headers['User-agent']
  end

  def test_basic_auth_sets_header
    conn = connection
    assert_nil conn.headers['Authorization']

    conn.basic_auth 'Aladdin', 'open sesame'
    assert auth = conn.headers['Authorization']
    assert_equal 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==', auth
  end

  def test_auto_parses_basic_auth_from_url_and_unescapes
    conn = connection :url => "http://foo%40bar.com:pass%20word@sushi.com/fish"
    assert auth = conn.headers['Authorization']
    assert_equal Faraday::RackBuilder::Request::BasicAuthentication.header("foo@bar.com", "pass word"), auth
  end

  def test_token_auth_sets_header
    conn = connection
    assert_nil conn.headers['Authorization']

    conn.token_auth 'abcdef', :nonce => 'abc'
    assert auth = conn.headers['Authorization']
    assert_match(/^Token /, auth)
    assert_match(/token="abcdef"/, auth)
    assert_match(/nonce="abc"/, auth)
  end

  def test_build_url_uses_connection_host_as_default_uri_host
    conn = connection
    conn.host = 'sushi.com'
    uri = conn.build_url("/sake.html")
    assert_equal 'sushi.com', uri.host
  end

  def test_build_url_overrides_connection_port_for_absolute_urls
    conn = connection
    conn.port = 23
    uri = conn.build_url("http://sushi.com")
    assert_equal 80, uri.port
  end

  def test_build_url_uses_connection_scheme_as_default_uri_scheme
    conn = connection 'http://sushi.com'
    uri = conn.build_url("/sake.html")
    assert_equal 'http', uri.scheme
  end

  def test_build_url_uses_connection_path_prefix_to_customize_path
    conn = connection
    conn.path_prefix = '/fish'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_uses_root_connection_path_prefix_to_customize_path
    conn = connection
    conn.path_prefix = '/'
    uri = conn.build_url("sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_forces_connection_path_prefix_to_be_absolute
    conn = connection
    conn.path_prefix = 'fish'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_ignores_connection_path_prefix_trailing_slash
    conn = connection
    conn.path_prefix = '/fish/'
    uri = conn.build_url("sake.html")
    assert_equal '/fish/sake.html', uri.path
  end

  def test_build_url_allows_absolute_uri_to_ignore_connection_path_prefix
    conn = connection
    conn.path_prefix = '/fish'
    uri = conn.build_url("/sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_parses_url_params_into_path
    conn = connection
    uri = conn.build_url("http://sushi.com/sake.html")
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_doesnt_add_ending_slash_given_nil_url
    conn = connection
    conn.url_prefix = "http://sushi.com/nigiri"
    uri = conn.build_url(nil)
    assert_equal "/nigiri", uri.path
  end

  def test_build_url_doesnt_add_ending_slash_given_empty_url
    conn = connection
    conn.url_prefix = "http://sushi.com/nigiri"
    uri = conn.build_url('')
    assert_equal "/nigiri", uri.path
  end

  def test_build_url_parses_url_params_into_query
    conn = connection
    uri = conn.build_url("http://sushi.com/sake.html", 'a[b]' => '1 + 2')
    assert_equal "a%5Bb%5D=1+%2B+2", uri.query
  end

  def test_build_url_escapes_per_spec
    conn = connection
    uri = conn.build_url('http:/', 'a' => '1+2 foo~bar.-baz')
    assert_equal "a=1%2B2+foo~bar.-baz", uri.query
  end

  def test_build_url_bracketizes_nested_params_in_query
    conn = connection
    uri = conn.build_url("http://sushi.com/sake.html", 'a' => {'b' => 'c'})
    assert_equal "a%5Bb%5D=c", uri.query
  end

  def test_build_url_bracketizes_repeated_params_in_query
    conn = connection
    uri = conn.build_url("http://sushi.com/sake.html", 'a' => [1, 2])
    assert_equal "a%5B%5D=1&a%5B%5D=2", uri.query
  end

  def test_build_url_without_braketizing_repeated_params_in_query
    conn = connection
    conn.options.params_encoder = Faraday::FlatParamsEncoder
    uri = conn.build_url("http://sushi.com/sake.html", 'a' => [1, 2])
    assert_equal "a=1&a=2", uri.query
  end

  def test_build_url_parses_url
    conn = connection
    uri = conn.build_url("http://sushi.com/sake.html")
    assert_equal "http",       uri.scheme
    assert_equal "sushi.com",  uri.host
    assert_equal '/sake.html', uri.path
  end

  def test_build_url_parses_url_and_changes_scheme
    conn = connection :url => "http://sushi.com/sushi"
    conn.scheme = 'https'
    uri = conn.build_url("sake.html")
    assert_equal 'https://sushi.com/sushi/sake.html', uri.to_s
  end

  def test_build_url_handles_uri_instances
    conn = connection
    uri = conn.build_url(URI('/sake.html'))
    assert_equal '/sake.html', uri.path
  end

  def test_proxy_accepts_string
    with_env 'http_proxy', "http://duncan.proxy.com:80" do
      conn = connection
      conn.proxy 'http://proxy.com'
      assert_equal 'proxy.com', conn.proxy.host
    end
  end

  def test_proxy_accepts_uri
    with_env 'http_proxy', "http://duncan.proxy.com:80" do
      conn = connection
      conn.proxy URI.parse('http://proxy.com')
      assert_equal 'proxy.com', conn.proxy.host
    end
  end

  def test_proxy_accepts_hash_with_string_uri
    with_env 'http_proxy', "http://duncan.proxy.com:80" do
      conn = connection
      conn.proxy :uri => 'http://proxy.com', :user => 'rick'
      assert_equal 'proxy.com', conn.proxy.host
      assert_equal 'rick',      conn.proxy.user
    end
  end

  def test_proxy_accepts_hash
    with_env 'http_proxy', "http://duncan.proxy.com:80" do
      conn = connection
      conn.proxy :uri => URI.parse('http://proxy.com'), :user => 'rick'
      assert_equal 'proxy.com', conn.proxy.host
      assert_equal 'rick',      conn.proxy.user
    end
  end

  def test_proxy_accepts_http_env
    with_env 'http_proxy', "http://duncan.proxy.com:80" do
      conn = connection
      assert_equal 'duncan.proxy.com', conn.proxy.host
    end
  end

  def test_proxy_accepts_http_env_with_auth
    with_env 'http_proxy', "http://a%40b:my%20pass@duncan.proxy.com:80" do
      conn = connection
      assert_equal 'a@b',     conn.proxy.user
      assert_equal 'my pass', conn.proxy.password
    end
  end

  def test_dups_connection_object
    conn = connection 'http://sushi.com/foo',
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

    assert_equal 2, other.builder.handlers.size
    assert_equal 2, conn.builder.handlers.size
    assert !conn.headers.key?('content-length')
    assert !conn.params.key?('b')
  end

  def test_init_with_block
    conn = connection { }
    assert_equal 0, conn.builder.handlers.size
  end

  def test_init_with_block_yields_connection
    conn = connection(:params => {'a'=>'1'}) { |faraday|
      faraday.adapter :net_http
      faraday.url_prefix = 'http://sushi.com/omnom'
      assert_equal '1', faraday.params['a']
    }
    assert_equal 1, conn.builder.handlers.size
    assert_equal '/omnom', conn.path_prefix
  end

  def connection(options = nil, &block)
    raise NotImplementedError, "Define a #connection helper that passes in a :builder_class"
  end
end

