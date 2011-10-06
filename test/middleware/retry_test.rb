require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

module Middleware
  class RetryTest < Faraday::TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @conn = Faraday.new do |b|
        b.request :retry, 2
        b.adapter :test, @stubs
      end
    end

    def test_retries
      times_called = 0

      @stubs.post("/echo") do
        times_called += 1
        raise "Error occurred"
      end

      @conn.post("/echo") rescue nil
      assert_equal times_called, 3
    end
  end
end
