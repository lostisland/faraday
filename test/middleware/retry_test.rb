require File.expand_path("../../helper", __FILE__)

module Middleware
  class RetryTest < Faraday::TestCase
    def setup
      @times_called = 0
    end

    def conn(*retry_args)
      Faraday.new do |b|
        b.request :retry, *retry_args
        b.adapter :test do |stub|
          ['get', 'post'].each do |method|
            stub.send(method, '/unstable') {
              @times_called += 1
              @explode.call @times_called
            }
          end
        end
      end
    end

    def test_unhandled_error
      @explode = lambda {|n| raise "boom!" }
      assert_raises(RuntimeError) { conn.get("/unstable") }
      assert_equal 1, @times_called
    end

    def test_handled_error
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn.get("/unstable") }
      assert_equal 3, @times_called
    end

    def test_legacy_max_retries
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn(1).get("/unstable") }
      assert_equal 2, @times_called
    end

    def test_legacy_max_negative_retries
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn(-9).get("/unstable") }
      assert_equal 1, @times_called
    end

    def test_new_max_retries
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn(:max => 3).get("/unstable") }
      assert_equal 4, @times_called
    end

    def test_new_max_negative_retries
      @explode = lambda { |n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) { conn(:max => -9).get("/unstable") }
      assert_equal 1, @times_called
    end

    def test_interval
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      started  = Time.now
      assert_raises(Errno::ETIMEDOUT) {
        conn(:max => 2, :interval => 0.1).get("/unstable")
      }
      assert_in_delta 0.2, Time.now - started, 0.04
    end

    def test_calls_sleep_amount
      explode_app = MiniTest::Mock.new
      explode_app.expect(:call, nil, [{:body=>nil}])
      def explode_app.call(env)
        raise Errno::ETIMEDOUT
      end

      retry_middleware = Faraday::Request::Retry.new(explode_app)
      class << retry_middleware
        attr_accessor :sleep_amount_retries

        def sleep_amount(retries)
          self.sleep_amount_retries.delete(retries)
          0
        end
      end
      retry_middleware.sleep_amount_retries = [2, 1]

      assert_raises(Errno::ETIMEDOUT) {
        retry_middleware.call({:method => :get})
      }

      assert_empty retry_middleware.sleep_amount_retries
    end

    def test_exponential_backoff
      middleware = Faraday::Request::Retry.new(nil, :max => 5, :interval => 0.1, :backoff_factor => 2)
      assert_equal middleware.sleep_amount(5), 0.1
      assert_equal middleware.sleep_amount(4), 0.2
      assert_equal middleware.sleep_amount(3), 0.4
    end

    def test_random_additional_interval_amount
      middleware = Faraday::Request::Retry.new(nil, :max => 2, :interval => 0.1, :interval_randomness => 1.0)
      sleep_amount = middleware.sleep_amount(2)
      assert_operator sleep_amount, :>=, 0.1
      assert_operator sleep_amount, :<=, 0.2
      middleware = Faraday::Request::Retry.new(nil, :max => 2, :interval => 0.1, :interval_randomness => 0.5)
      sleep_amount = middleware.sleep_amount(2)
      assert_operator sleep_amount, :>=, 0.1
      assert_operator sleep_amount, :<=, 0.15
      middleware = Faraday::Request::Retry.new(nil, :max => 2, :interval => 0.1, :interval_randomness => 0.25)
      sleep_amount = middleware.sleep_amount(2)
      assert_operator sleep_amount, :>=, 0.1
      assert_operator sleep_amount, :<=, 0.125
    end

    def test_custom_exceptions
      @explode = lambda {|n| raise "boom!" }
      assert_raises(RuntimeError) {
        conn(:exceptions => StandardError).get("/unstable")
      }
      assert_equal 3, @times_called
    end

    def test_should_stop_retrying_if_block_returns_false_checking_env
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      check = lambda { |env,exception| env[:method] != :post }
      assert_raises(Errno::ETIMEDOUT) {
        conn(:retry_if => check).post("/unstable")
      }
      assert_equal 1, @times_called
    end

    def test_should_stop_retrying_if_block_returns_false_checking_exception
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      check = lambda { |env,exception| !exception.kind_of?(Errno::ETIMEDOUT) }
      assert_raises(Errno::ETIMEDOUT) {
        conn(:retry_if => check).post("/unstable")
      }
      assert_equal 1, @times_called
    end

    def test_should_not_call_retry_if_for_idempotent_methods_if_methods_unspecified
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      check = lambda { |env,exception| raise "this should have never been called" }
      assert_raises(Errno::ETIMEDOUT) {
        conn(:retry_if => check).get("/unstable")
      }
      assert_equal 3, @times_called
    end

    def test_should_not_retry_for_non_idempotent_method_if_methods_unspecified
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      assert_raises(Errno::ETIMEDOUT) {
        conn.post("/unstable")
      }
      assert_equal 1, @times_called
    end

    def test_should_not_call_retry_if_for_specified_methods
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      check = lambda { |env,exception| raise "this should have never been called" }
      assert_raises(Errno::ETIMEDOUT) {
        conn(:retry_if => check, :methods => [:post]).post("/unstable")
      }
      assert_equal 3, @times_called
    end

    def test_should_call_retry_if_for_empty_method_list
      @explode = lambda {|n| raise Errno::ETIMEDOUT }
      check = lambda { |env,exception| @times_called < 2 }
      assert_raises(Errno::ETIMEDOUT) {
        conn(:retry_if => check, :methods => []).get("/unstable")
      }
      assert_equal 2, @times_called
    end

  end
end
