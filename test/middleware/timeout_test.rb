require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

module Middleware
  class TimeoutTest < Faraday::TestCase
    def setup
      @conn = Faraday.new do |b|
        b.request :timeout, 0.01 # 10 ms
        b.adapter :test do |stub|
          stub.post("/echo") do |env|
            sleep(1)
          end
        end
      end
    end

    def test_request_times_out
      assert_raise(TimeoutError) { @conn.post("/echo") }
    end
  end
end
