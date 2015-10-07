require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

module Middleware
  class RetryTest < Faraday::TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @conn = Faraday.new do |b|
        b.request :retry, 2
        b.use ContentValidator
        b.adapter :test, @stubs
      end
    end

    ContentValidator = Struct.new(:app) do
      def call(env)
        response = app.call(env)
        type = response[:content_type]
        raise "wrong content-type: %p" % type unless type == "application/json"
      end
    end

    def test_retries
      times_called = 0

      @stubs.post("/echo") do
        times_called += 1
        [200, {}, "hello"]
      end

      @conn.post("/echo") rescue nil
      assert_equal times_called, 3
    end

    def test_retry_with_body
      times_called = 0
      bodies_received = []

      @stubs.post("/echo") do |env|
        times_called += 1
        bodies_received << env[:body]
        if times_called < 2
          [200, {"Content-type" => "text/plain"}, "hello"]
        else
          [200, {"Content-type" => "application/json"}, '{"message": "hello"}']
        end
      end

      body = {:foo => "bar"}
      @conn.post("/echo", body)

      assert_equal times_called, 2
      assert_same body, bodies_received[0]
      assert_same body, bodies_received[1]
    end
  end
end
