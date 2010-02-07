require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ResponseMiddlewareTest < Faraday::TestCase
  describe "parsing json" do
    [:yajl, :rails_json].each do |key|
      parser = Faraday::Response.lookup_module(key)
      next if !parser.loaded?
      it "uses #{parser} to parse json content" do
        @connection = Faraday::Connection.new do |b|
          b.adapter :test do |stub|
            stub.get('json')  { [200, {'Content-Type' => 'text/html'}, "[1,2,3]"] }
          end
          b.use parser
        end
        response = @connection.get('json')
        assert response.success?
        assert_equal [1,2,3], response.body
      end

      it "uses #{parser} to skip blank content" do
        @connection = Faraday::Connection.new do |b|
          b.adapter :test do |stub|
            stub.get('blank') { [200, {'Content-Type' => 'text/html'}, ''] }
          end
          b.use parser
        end
        response = @connection.get('blank')
        assert response.success?
        assert_equal nil, response.body
      end

      it "uses #{parser} to skip nil content" do
        @connection = Faraday::Connection.new do |b|
          b.adapter :test do |stub|
            stub.get('nil') { [200, {'Content-Type' => 'text/html'}, nil] }
          end
          b.use parser
        end
        response = @connection.get('nil')
        assert response.success?
        assert_equal nil, response.body
      end
    end
  end
end
