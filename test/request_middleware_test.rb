require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class RequestMiddlewareTest < Faraday::TestCase
  [:yajl, :rails_json].each do |key|
    encoder = Faraday::Request.lookup_module(key)
    next if !encoder.loaded?

    define_method "test_encodes_json_with_#{key}" do
      assert_equal %({"a":1}), create_json_connection(encoder).post('echo_body', :a => 1).body
    end
  end

private
  def create_json_connection(encoder)
    Faraday::Connection.new do |b|
      b.use encoder
      b.adapter :test do |stub|
        stub.post('echo_body', '{"a":1}') { |env| [200, {'Content-Type' => 'text/html'}, env[:body]] }
      end
    end
  end
end
