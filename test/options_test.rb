require File.expand_path('../helper', __FILE__)

class OptionsTest < Faraday::TestCase
  class Options < Faraday::Options.new(:a, :b)
  end

  def test_from_options
    options = Options.new 1

    value = Options.from(options)
    assert_equal 1, value.a
    assert_nil value.b
  end

  def test_from_hash
    options = Options.from :a => 1
    assert_kind_of Options, options
    assert_equal 1, options.a
    assert_nil options.b
  end

  def test_from_nil
    options = Options.from(nil)
    assert_kind_of Options, options
    assert_nil options.a
    assert_nil options.b
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

