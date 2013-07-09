require File.expand_path('../helper', __FILE__)

class ProxyMiddlewareTest < Faraday::TestCase
  def setup
    # clear any proxy environment variables
    @backup_envs = {}
    proxy_envs = %w{http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY}
    proxy_envs.each {|key| @backup_envs[key] = ENV.delete(key) }
  end
  
  def teardown
    # ...and put them back again
    @backup_envs.each {|key, value| ENV[key] = value }
  end

  def connection(url='http://example.com')
    Faraday.new(url) do |builder|
      yield builder
      builder.adapter :test do |stub|
        stub.get('/test') {[ 200, {}, 'shrimp' ]}
      end
    end
  end

  def test_no_proxy_set_by_default
    response = connection{ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_raise_when_non_http_or_https_proxy_passed_in
    conn = connection('http://example.com'){ |b| b.request :proxy, 'ftp://example.com'}
    assert_raises TypeError do conn.get('/test') end
  end

  def test_http_proxy_in_env_is_set
    ENV['http_proxy'] = 'http://proxy.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://proxy.com', proxy_options.uri.to_s
  end

  def test_http_proxy_with_username_and_password
    ENV['http_proxy'] = 'http://username:pass@proxy.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'proxy.com', proxy_options.uri.host
    assert_equal 'username',  proxy_options.user
    assert_equal 'pass',      proxy_options.password
  end

  def test_http_proxy_in_env_is_set_in_upper_case
    ENV['HTTP_PROXY'] = 'http://proxy.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://proxy.com', proxy_options.uri.to_s
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

  def test_upper_case_env_trumps_lower_case
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['HTTP_PROXY'] = 'http://upper.proxy.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://upper.proxy.com', proxy_options.uri.to_s
  end

  def test_explicit_proxy_trumps_env
    ENV['HTTP_PROXY'] = 'http://env.proxy.com'
    conn = connection { |b| b.request :proxy, 'http://ex.proxy.com' }
    response = conn.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://ex.proxy.com', proxy_options.uri.to_s
  end

  def test_proxy_set_and_url_in_no_proxy_list_removes_proxy
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_proxy_set_and_url_not_in_no_proxy_list_sets_proxy
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example2.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://proxy.com', proxy_options.uri.to_s
  end

  def test_proxy_set_in_multi_element_no_proxy_list
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example0.com,example.com,example1.com'
    response = connection { |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_proxy_ignored_when_ports_match_in_no_proxy_list
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example.com:7171'
    response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_proxy_ignored_when_port_is_not_set_in_no_proxy_list
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example.com'
    response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_proxy_set_when_ports_mismatch_in_no_proxy_list
    ENV['http_proxy'] = 'http://proxy.com'
    ENV['no_proxy']   = 'example.com:3000'
    response = connection('http://example.com:7171'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'http://proxy.com', proxy_options.uri.to_s
  end

  def test_https_proxy_set_given_https_url
    ENV['https_proxy'] = 'https://ssl.proxy.com'
    response = connection('https://example.com'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    refute_nil proxy_options
    assert_equal 'https://ssl.proxy.com', proxy_options.uri.to_s
  end

  def test_https_ignored_given_match_in_no_proxy_list
    ENV['https_proxy'] = 'https://ssl.proxy.com'
    ENV['no_proxy'] = 'example.com'

    response = connection('https://example.com'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

  def test_https_ignored_when_http_url_requested
    ENV['https_proxy'] = 'https://ssl.proxy.com'

    response = connection('http://example.com'){ |b| b.request :proxy }.get('/test')
    proxy_options = response.env.request.proxy

    assert_nil proxy_options
  end

end
