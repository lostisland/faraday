require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class RequestMiddlewareTest < Faraday::TestCase
  describe "encoding json" do
    [:yajl, :rails_json].each do |key|
      encoder = Faraday::Request.lookup_module(key)
      next if !encoder.loaded?
      it "uses #{encoder}" do
        @connection = Faraday::Connection.new do |b|
          b.use encoder
          b.adapter :test do |stub|
            stub.post('echo_body', '{"a":1}') { |env| [200, {'Content-Type' => 'text/html'}, env[:body]] }
          end
        end
        assert_equal %({"a":1}), @connection.post('echo_body', :a => 1).body
      end
    end
  end
end
