class TestParameters < Faraday::TestCase
  def test_encode_empty_string_array_value
    expected = 'baz=&foo%5Bbar%5D='
    assert_equal expected, Faraday::NestedParamsEncoder.encode(foo: {bar: ''}, baz: '')
  end

  def test_encode_nil_array_value
    expected = 'baz&foo%5Bbar%5D'
    assert_equal expected, Faraday::NestedParamsEncoder.encode(foo: {bar: nil}, baz: nil)
  end

  def test_encode_empty_array_value
    expected = 'baz%5B%5D&foo%5Bbar%5D%5B%5D'
    Faraday::NestedParamsEncoder.encode(foo: { bar: [] }, baz: [])
    assert_equal expected, Faraday::NestedParamsEncoder.encode(foo: { bar: [] }, baz: [])
  end
end
