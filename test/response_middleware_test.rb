require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseMiddlewareTest < Faraday::TestCase
  valid_middleware = [:yajl, :rails_json].
    select { |key| Faraday::Request.lookup_module(key).loaded? }

  if valid_middleware.include?(:yajl)
    def test_uses_yajl_to_parse_json_content
      response = create_json_connection(:yajl).get('json')
      assert response.success?
      assert_equal [1,2,3], response.body
    end

    def test_uses_yajl_to_skip_blank_content
      response = create_json_connection(:yajl).get('blank')
      assert response.success?
      assert !response.body
    end

    def test_uses_yajl_to_skip_nil_content
      response = create_json_connection(:yajl).get('nil')
      assert response.success?
      assert !response.body
    end
  end

  if valid_middleware.include?(:rails_json)
    def test_uses_rails_json_to_parse_json_content
      response = create_json_connection(:rails_json).get('json')
      assert response.success?
      assert_equal [1,2,3], response.body
    end

    def test_uses_rails_json_to_skip_blank_content
      response = create_json_connection(:rails_json).get('blank')
      assert response.success?
      assert !response.body
    end

    def test_uses_rails_json_to_skip_nil_content
      response = create_json_connection(:rails_json).get('nil')
      assert response.success?
      assert !response.body
    end
  end

  def create_json_connection(encoder_key)
    Faraday::Connection.new do |b|
      b.adapter :test do |stub|
        stub.get('json')  { [200, {'Content-Type' => 'text/html'}, "[1,2,3]"] }
        stub.get('blank') { [200, {'Content-Type' => 'text/html'}, ''] }
        stub.get('nil')   { [200, {'Content-Type' => 'text/html'}, nil] }
      end
      b.use Faraday::Response.lookup_module(encoder_key)
    end
  end
end
