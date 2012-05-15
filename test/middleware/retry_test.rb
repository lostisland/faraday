require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

module Middleware
  class RetryTest < Faraday::TestCase
    def test_default_exception
      test_retry { raise Faraday::Error::TimeoutError, 'execution expired' }
    end

    def test_custom_exception
      @exceptions = ArgumentError

      test_retry    { raise ArgumentError, 'there has been an error' }
      test_no_retry { raise Faraday::Error::TimeoutError, 'execution expired' }
    end

    def test_multiple_custom_exceptions
      @exceptions = [ArgumentError, Faraday::Error::TimeoutError]

      test_retry { raise ArgumentError, 'there has been an error' }
      test_retry { raise Faraday::Error::TimeoutError, 'execution expired' }
    end

    private

    def prepare_new_connection
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post("/echo") do
        @times_called += 1
        yield
      end

      Faraday.new do |b|
        b.request :retry, 2, :on => @exceptions
        b.adapter :test, stubs
      end
    end

    def test_retry(&block)
      @times_called = 0

      conn = prepare_new_connection(&block)
      conn.post("/echo") rescue nil

      assert_equal 3, @times_called
    end

    def test_no_retry(&block)
      @times_called = 0

      conn = prepare_new_connection(&block)
      conn.post("/echo") rescue nil

      assert_equal 1, @times_called
    end
  end
end
