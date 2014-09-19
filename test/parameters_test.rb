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

  def test_raises_typeerror_nested
    error = assert_raises TypeError do
      Faraday::NestedParamsEncoder.encode("")
    end
    assert_equal "Can't convert String into Hash.", error.message
  end

  def test_raises_typeerror_flat
    error = assert_raises TypeError do
      Faraday::FlatParamsEncoder.encode("")
    end
    assert_equal "Can't convert String into Hash.", error.message
  end

  def test_decode_array_nested
    query = "a[1]=one&a[2]=two&a[3]=three"
    expected = {"a" => ["one", "two", "three"]}
    assert_equal expected, Faraday::NestedParamsEncoder.decode(query)
  end

  def test_decode_array_flat
    query = "a=one&a=two&a=three"
    expected = {"a" => ["one", "two", "three"]}
    assert_equal expected, Faraday::FlatParamsEncoder.decode(query)
  end

  def test_nested_decode_hash
    query = "a[b1]=one&a[b2]=two&a[b][c]=foo"
    expected = {"a" => {"b1" => "one", "b2" => "two", "b" => {"c" => "foo"}}}
    assert_equal expected, Faraday::NestedParamsEncoder.decode(query)
  end

  def test_encode_nil_nested
    assert_equal "a=", Faraday::NestedParamsEncoder.encode("a" => nil)
  end

  def test_encode_nil_flat
    assert_equal "a", Faraday::FlatParamsEncoder.encode("a" => nil)
  end
end
