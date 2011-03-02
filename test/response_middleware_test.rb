require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.response :json
      b.adapter :test do |stub|
        stub.get('json')  { [200, {'Content-Type' => 'text/html'}, "[1,2,3]"] }
        stub.get('blank') { [200, {'Content-Type' => 'text/html'}, ''] }
        stub.get('nil')   { [200, {'Content-Type' => 'text/html'}, nil] }
        stub.get("bad_json") {[200, {'Content-Type' => 'text/html'}, '<body></body>']}
      end
    end
  end

  def test_uses_json_to_parse_json_content
    response = @conn.get('json')
    assert response.success?
    assert_equal [1,2,3], response.body
  end

  def test_uses_json_to_skip_blank_content
    response = @conn.get('blank')
    assert response.success?
    assert_nil response.body
  end

  def test_uses_json_to_skip_nil_content
    response = @conn.get('nil')
    assert response.success?
    assert_nil response.body
  end

  def test_uses_json_to_raise_Faraday_Error_Parsing_with_no_json_content
    assert_raises Faraday::Error::ParsingError do
      @conn.get('bad_json')
    end
  end
end
