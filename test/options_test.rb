require File.expand_path('../helper', __FILE__)

class OptionsTest < Faraday::TestCase
  class SubOptions < Faraday::Options.new(:sub); end
  class Options < Faraday::Options.new(:a, :b, :c)
    options :c => SubOptions
  end

  def test_request_proxy_setter
    options = Faraday::RequestOptions.new
    assert_nil options.proxy

    assert_raises NoMethodError do
      options[:proxy] = {:booya => 1}
    end

    options[:proxy] = {:user => 'user'}
    assert_kind_of Faraday::ProxyOptions, options.proxy
    assert_equal 'user', options.proxy.user

    options.proxy = nil
    assert_nil options.proxy
  end

  def test_proxy_options_from_string
    options = Faraday::ProxyOptions.from 'http://user:pass@example.org'
    assert_equal 'user', options.user
    assert_equal 'pass', options.password
    assert_kind_of URI, options.uri
    assert_equal '', options.path
    assert_equal 80, options.port
    assert_equal 'example.org', options.host
    assert_equal 'http', options.scheme
  end

  def test_proxy_options_hash_access
    proxy = Faraday::ProxyOptions.from 'http://a%40b:pw%20d@example.org'
    assert_equal 'a@b', proxy[:user]
    assert_equal 'a@b', proxy.user
    assert_equal 'pw d', proxy[:password]
    assert_equal 'pw d', proxy.password
  end

  def test_proxy_options_no_auth
    proxy = Faraday::ProxyOptions.from 'http://example.org'
    assert_nil proxy.user
    assert_nil proxy.password
  end

  def test_from_options
    options = Options.new 1

    value = Options.from(options)
    assert_equal 1, value.a
    assert_nil value.b
  end

  def test_from_options_with_sub_object
    sub = SubOptions.new 1
    options = Options.from :a => 1, :c => sub
    assert_kind_of Options, options
    assert_equal 1, options.a
    assert_nil options.b
    assert_kind_of SubOptions, options.c
    assert_equal 1, options.c.sub
  end

  def test_from_hash
    options = Options.from :a => 1
    assert_kind_of Options, options
    assert_equal 1, options.a
    assert_nil options.b
  end

  def test_from_hash_with_sub_object
    options = Options.from :a => 1, :c => {:sub => 1}
    assert_kind_of Options, options
    assert_equal 1, options.a
    assert_nil options.b
    assert_kind_of SubOptions, options.c
    assert_equal 1, options.c.sub
  end

  def test_inheritance
    subclass = Class.new(Options)
    options = subclass.from(:c => {:sub => 'hello'})
    assert_kind_of SubOptions, options.c
    assert_equal 'hello', options.c.sub
  end

  def test_from_deep_hash
    hash = {:b => 1}
    options = Options.from :a => hash
    assert_equal 1, options.a[:b]

    hash[:b] = 2
    assert_equal 1, options.a[:b]

    options.a[:b] = 3
    assert_equal 2, hash[:b]
    assert_equal 3, options.a[:b]
  end

  def test_from_nil
    options = Options.from(nil)
    assert_kind_of Options, options
    assert_nil options.a
    assert_nil options.b
  end

  def test_invalid_key
    assert_raises NoMethodError do
      Options.from :invalid => 1
    end
  end

  def test_update
    options = Options.new 1
    assert_equal 1, options.a
    assert_nil options.b

    updated = options.update :a => 2, :b => 3
    assert_equal 2, options.a
    assert_equal 3, options.b
    assert_equal options, updated
  end

  def test_delete
    options = Options.new 1
    assert_equal 1, options.a
    assert_equal 1, options.delete(:a)
    assert_nil options.a
  end

  def test_merge
    options = Options.new 1
    assert_equal 1, options.a
    assert_nil options.b

    dup = options.merge :a => 2, :b => 3
    assert_equal 2, dup.a
    assert_equal 3, dup.b
    assert_equal 1, options.a
    assert_nil options.b
  end

  def test_env_access_member
    e = Faraday::Env.new
    assert_nil e.method
    e.method = :get
    assert_equal :get, e.method
  end

  def test_env_access_symbol_non_member
    e = Faraday::Env.new
    assert_nil e[:custom]
    e[:custom] = :boom
    assert_equal :boom, e[:custom]
  end

  def test_env_access_string_non_member
    e = Faraday::Env.new
    assert_nil e["custom"]
    e["custom"] = :boom
    assert_equal :boom, e["custom"]
  end

  def test_env_fetch_ignores_false
    ssl = Faraday::SSLOptions.new
    ssl.verify = false
    assert !ssl.fetch(:verify, true)
  end
end
