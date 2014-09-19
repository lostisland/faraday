require File.expand_path("../helper", __FILE__)

class TestParameters < Faraday::TestCase
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

  def test_escaping_safe_buffer_nested
    monies = FakeSafeBuffer.new("$32,000.00")
    assert_equal "a=%2432%2C000.00", Faraday::NestedParamsEncoder.encode("a" => monies)
  end

  def test_escaping_safe_buffer_flat
    monies = FakeSafeBuffer.new("$32,000.00")
    assert_equal "a=%2432%2C000.00", Faraday::FlatParamsEncoder.encode("a" => monies)
  end
end
