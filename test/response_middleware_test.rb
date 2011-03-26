require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.response :json
      b.response :raise_error
      b.adapter :test do |stub|
        stub.get('json')      { [200, {'Content-Type' => 'application/json; charset=utf-8'}, "[1,2,3]"] }
        stub.get('blank')     { [200, {'Content-Type' => 'application/json'}, ''] }
        stub.get('nil')       { [200, {'Content-Type' => 'application/json'}, nil] }
        stub.get('bad_json')  { [200, {'Content-Type' => 'application/json'}, '<body></body>']}
        stub.get('non_json')  { [200, {'Content-Type' => 'text/html'}, '<body></body>']}
        stub.get('not-found') { [404, {'X-Reason' => 'because'}, 'keep looking']}
        stub.get('error')     { [500, {'X-Error' => 'bailout'}, 'fail']}
      end
    end
  end

  def process_only(*types)
    handler = Faraday::Response::JSON
    @conn.builder.swap handler, handler, :content_type => types
  end

  def test_uses_json_to_parse_json_content
    response = @conn.get('json')
    assert response.success?
    assert_equal [1,2,3], response.body
  end

  def test_uses_json_to_parse_json_content_conditional
    process_only('application/json')
    response = @conn.get('json')
    assert response.success?
    assert_equal [1,2,3], response.body
  end

  def test_uses_json_to_parse_json_content_conditional_with_regexp
    process_only(%r{/(x-)?json$})
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
  
  def test_non_json_response
    assert_raises Faraday::Error::ParsingError do
      @conn.get('non_json')
    end
  end
  
  def test_non_json_response_conditional
    process_only('application/json')
    response = @conn.get('non_json')
    assert_equal 'text/html', response.headers['Content-Type']
    assert_equal '<body></body>', response.body
  end

  def test_raises_error
    begin
      @conn.get('not-found')
    rescue Faraday::Error::ResourceNotFound => error
      assert_equal 'the server responded with status 404', error.message
      assert_equal 'because', error.response[:headers]['X-Reason']
    end

    begin
      @conn.get('error')
    rescue Faraday::Error::ClientError => error
      assert_equal 'the server responded with status 500', error.message
      assert_equal 'bailout', error.response[:headers]['X-Error']
    end
  end
end
