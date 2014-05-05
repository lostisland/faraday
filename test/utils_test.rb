require File.expand_path('../helper', __FILE__)

class TestUtils < Faraday::TestCase

  # emulates ActiveSupport::SafeBuffer#gsub
  FakeSafeBuffer = Struct.new(:string) do
    def to_s() self end
    def gsub(regex)
      string.gsub(regex) {
        match, = $&, '' =~ /a/
        yield match
      }
    end
  end

  def test_escaping_safe_buffer
    str = FakeSafeBuffer.new('$32,000.00')
    assert_equal '%2432%2C000.00', Faraday::Utils.escape(str)
  end

  def test_replace_header_hash
    headers = Faraday::Utils::Headers.new('authorization' => 't0ps3cr3t!')
    assert headers.include?('authorization')

    headers.replace({'content-type' => 'text/plain'})

    assert !headers.include?('authorization')
  end
end

