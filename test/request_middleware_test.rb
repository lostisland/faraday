require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class RequestMiddlewareTest < Faraday::TestCase
  valid_middleware = [:yajl, :rails_json].
    select { |key| Faraday::Request.lookup_module(key).loaded? }

  if valid_middleware.include?(:yajl)
    def test_encodes_json_with_yajl
      assert_equal %({"a":1}), create_json_connection(:yajl).post('echo_body', :a => 1).body
    end
  end

  if valid_middleware.include?(:rails_json)
    def test_encodes_json_with_rails_json
      assert_equal %({"a":1}), create_json_connection(:rails_json).post('echo_body', :a => 1).body
    end
  end

private
  def create_json_connection(encoder_key)
    Faraday::Connection.new do |b|
      b.use Faraday::Request.lookup_module(encoder_key)
      b.adapter :test do |stub|
        stub.post('echo_body', '{"a":1}') { |env| [200, {'Content-Type' => 'text/html'}, env[:body]] }
      end
    end
  end
end
