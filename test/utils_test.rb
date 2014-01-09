require File.expand_path('../helper', __FILE__)

class TestUtils < Faraday::TestCase
  def setup
    @url = "http://example.com/abc"
  end

  # emulates ActiveSupport::SafeBuffer#gsub
  FakeSafeBuffer = Struct.new(:string) do
    def to_s() self end
    def gsub(regex)
      string.gsub(regex) {
        match, = $&, '' =~ /a/
        yield(match)
      }
    end
  end

  def test_escaping_safe_buffer
    str = FakeSafeBuffer.new('$32,000.00')
    assert_equal '%2432%2C000.00', Faraday::Utils.escape(str)
  end

  def test_parses_with_default
    with_default_uri_parser(nil) do
      uri = normalize(@url)
      assert_equal 'example.com', uri.host
    end
  end

  def test_parses_with_URI
    with_default_uri_parser(::URI) do
      uri = normalize(@url)
      assert_equal 'example.com', uri.host
    end
  end

  def test_parses_with_block
    with_default_uri_parser(lambda {|u| "booya#{"!" * u.size}" }) do
      assert_equal 'booya!!!!!!!!!!!!!!!!!!!!!!', normalize(@url)
    end
  end

  def normalize(url)
    Faraday::Utils::URI(url)
  end

  def with_default_uri_parser(parser)
    old_parser = Faraday::Utils.default_uri_parser
    begin
      Faraday::Utils.default_uri_parser = parser
      yield
    ensure
      Faraday::Utils.default_uri_parser = old_parser
    end
  end
end

