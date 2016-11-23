require File.expand_path('../helper', __FILE__)

class ProxyMiddlewareTest < Faraday::TestCase
  def with_env(new_env)
    old_env = {}

    new_env.each do |key, value|
      old_env[key] = ENV.fetch(key, false)
      ENV[key] = value
    end

    begin
      yield
    ensure
      old_env.each do |key, value|
        if value == false
          ENV.delete key
        else
          ENV[key] = value
        end
      end
    end
  end

  def connection(url='http://example.com')
    Faraday.new(url) do |builder|
      yield builder
      builder.adapter :test do |stub|
        stub.get('/test') {[ 200, {}, '' ]}
      end
    end
  end

  def test_no_proxy_set_by_default
    with_env 'HTTP_PROXY' => '', 'http_proxy' => nil do
      response = connection{ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_raise_when_non_http_or_https_proxy_passed_in
    conn = connection('http://example.com'){ |b| b.request :proxy, 'ftp://example.com'}
    assert_raises TypeError do conn.get('/test') end
  end

  def test_proxy_accepts_env_without_scheme
    with_env 'http_proxy' => "localhost:8888" do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'localhost', proxy_options.uri.host
      assert_equal 8888,      proxy_options.uri.port
    end
  end

  def test_http_proxy_in_env_is_set
    with_env 'HTTP_PROXY' => nil, 'http_proxy' => 'http://proxy.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_http_proxy_with_username_and_password
    with_env 'HTTP_PROXY' => nil, 'http_proxy' => 'http://username:pass@proxy.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'proxy.com', proxy_options.uri.host
      assert_equal 'username',  proxy_options.user
      assert_equal 'pass',      proxy_options.password
    end
  end

  def test_http_proxy_in_env_is_set_in_upper_case
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'http_proxy' => nil do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_http_proxy_set_explicitly
    conn = connection { |b| b.request :proxy, 'http://proxy.com' }
    response = conn.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://proxy.com', proxy_options.uri.to_s
  end

  def test_http_proxy_set_explicitly_with_username_and_password
    conn = connection { |b| b.request :proxy, 'http://proxy.com',
                                      :user => 'username',
                                      :password => 'pass' }
    response = conn.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'proxy.com', proxy_options.uri.host
    assert_equal 'username',  proxy_options.user
    assert_equal 'pass',      proxy_options.password
  end

  # this is to allow connection#proxy to behave as before
  def test_http_proxy_set_via_hash
    conn = connection { |b| b.request :proxy,
                                      {
                                          :uri => 'http://proxy.com',
                                          :user => 'username',
                                          :password => 'pass'
                                      }
    }
    response = conn.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'proxy.com', proxy_options.uri.host
    assert_equal 'username',  proxy_options.user
    assert_equal 'pass',      proxy_options.password
  end

  def test_http_proxy_with_encoded_username_and_password
    conn = connection { |b| b.request :proxy,
                                      {
                                          :uri => 'http://proxy.com',
                                          :user => '%27username%27',
                                          :password => '%27password%27'
                                      }
    }
    response = conn.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'proxy.com', proxy_options.uri.host
    assert_equal "'username'",  proxy_options.user
    assert_equal "'password'",      proxy_options.password
  end

  def test_lower_case_env_trumps_upper_case
    with_env 'http_proxy' => 'http://proxy.com', 'HTTP_PROXY' => 'http://upper.proxy.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_explicit_proxy_trumps_env
    with_env 'HTTP_PROXY' => 'http://env.proxy.com' do
      conn = connection { |b| b.request :proxy, 'http://ex.proxy.com' }
      response = conn.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://ex.proxy.com', proxy_options.uri.to_s
    end
  end

  def test_proxy_set_and_url_in_no_proxy_list_removes_proxy
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_proxy_set_and_url_not_in_no_proxy_list_sets_proxy
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example2.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_proxy_set_in_multi_element_no_proxy_list
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example0.com,example.com,example1.com' do
      response = connection { |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_proxy_ignored_when_ports_match_in_no_proxy_list
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example.com:7171' do
      response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_proxy_ignored_when_port_is_not_set_in_no_proxy_list
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example.com' do
      response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_proxy_set_when_ports_mismatch_in_no_proxy_list
    with_env 'HTTP_PROXY' => 'http://proxy.com', 'NO_PROXY' => 'example.com:3000' do
      response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_proxy_set_when_url_is_nil
    with_env 'HTTP_PROXY' => 'http://proxy.com' do
      response = connection(nil){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end

  def test_https_proxy_set_given_https_url
    with_env 'HTTPS_PROXY' => 'https://ssl.proxy.com' do
      response = connection('https://example.com'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'https://ssl.proxy.com', proxy_options.uri.to_s
    end
  end

  def test_https_ignored_given_match_in_no_proxy_list
    with_env 'HTTPS_PROXY' => 'https://ssl.proxy.com', 'NO_PROXY' => 'example.com' do
      response = connection('https://example.com'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_https_ignored_when_http_url_requested
    with_env 'http_proxy' => nil, 'HTTP_PROXY' => nil, 'HTTPS_PROXY' => 'https://ssl.proxy.com' do
      response = connection('http://example.com'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_https_ignored_given_domain
    with_env 'https_proxy' => 'http://proxy.com', 'no_proxy' => 'github.com' do
      %w(www.github.com pages.github.com).each do |url|
        response = connection("https://#{url}"){ |b| b.request :proxy }.get('/test')
        proxy_options = response.env.request.proxy

        assert_nil proxy_options
      end
    end
  end

  def test_https_ignored_given_match_subdomain
    with_env 'https_proxy' => 'http://proxy.com', 'no_proxy' => 'pages.github.com' do
      response = connection('https://pages.github.com'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      assert_nil proxy_options
    end
  end

  def test_https_set_given_match_subdomain
    with_env 'https_proxy' => 'http://proxy.com', 'no_proxy' => 'pages.github.com' do
      response = connection('https://github.com'){ |b| b.request :proxy }.get('/test')
      proxy_options = response.env.request.proxy

      refute_nil proxy_options
      assert_equal 'http://proxy.com', proxy_options.uri.to_s
    end
  end
end
