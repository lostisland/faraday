require File.expand_path('../helper', __FILE__)

module Parameters
  class NestedParamsEncoderTest < Faraday::TestCase
    def test_decode_common_query
      params = Faraday::NestedParamsEncoder.decode("foo1=bar1&foo2=bar2")
      assert_equal 'bar1', params["foo1"]
      assert_equal 'bar2', params["foo2"]
    end

    def test_encode_common_params
      params = {"foo1" => "bar1", "foo2" => "bar2"}
      assert_equal "foo1=bar1&foo2=bar2", Faraday::NestedParamsEncoder.encode(params)
    end

    def test_decode_blank_string_query
      params = Faraday::NestedParamsEncoder.decode("blank=&foo=bar")
      assert_equal '', params["blank"]
      assert_equal 'bar', params["foo"]
    end

    def test_encode_blank_string_params
      params = {"blank" => "", "foo" => "bar"}
      assert_equal "blank=&foo=bar", Faraday::NestedParamsEncoder.encode(params)
    end

    def test_decode_nil_string_query
      params = Faraday::NestedParamsEncoder.decode("foo=bar&nil")
      assert_equal nil, params["nil"]
      assert_equal 'bar', params["foo"]
    end

    def test_encode_nil_string_params
      params = {"foo" => "bar", "nil" => nil}
      assert_equal "foo=bar&nil", Faraday::NestedParamsEncoder.encode(params)
    end
  end
end