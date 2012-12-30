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
end

