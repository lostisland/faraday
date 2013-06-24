require File.expand_path('../helper', __FILE__)

class TestUtils < Faraday::TestCase
  def setup
    @url = "http://example.com/abc"
  end

  def teardown
    Faraday::Utils.default_uri_parser = nil
  end

  def test_escaping_safe_buffer
    str = FakeSafeBuffer.new('$32,000.00')
    assert_equal '%2432%2C000.00', Faraday::Utils.escape(str)
  end

  def test_parses_with_default
    assert_equal %(#<Method: Kernel.URI>), Faraday::Utils.default_uri_parser.to_s
    uri = normalize(@url)
    assert_equal 'example.com', uri.host
  end

  def test_parses_with_URI
    Faraday::Utils.default_uri_parser = ::URI
    assert_equal %(#<Method: URI.parse>), Faraday::Utils.default_uri_parser.to_s
    uri = normalize(@url)
    assert_equal 'example.com', uri.host
  end

  def test_parses_with_block
    Faraday::Utils.default_uri_parser = lambda do |uri|
      "booya#{"!" * uri.size}"
    end

    assert_equal 'booya!!!!!!!!!!!!!!!!!!!!!!', normalize(@url)
  end

  def normalize(url)
    Faraday::Utils::URI(url)
  end
end

