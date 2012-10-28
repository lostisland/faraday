require File.expand_path('../helper', __FILE__)
Faraday.require_lib 'callback_builder'

class CallbackBuilderTest < Faraday::TestCase
  class Upcaser
    attr_reader :builder
    attr_writer :request, :response

    def initialize(builder)
      @builder = builder
    end

    def on_request(req)
      @request = req
      req.body.upcase!
    end

    def on_response(res)
      @response = res
      res.body.upcase!
    end
  end

  class Adapter
    def initialize(builder)
      @builder = builder
    end

    def call(req)
      @builder.run_request_callbacks(req)

      res = Faraday::Response.new :status => 200, :body => 'booya',
        :response_headers => {"Content-Type" => "text/plain",
        'X-Body' => req.body}

      @builder.run_response_callbacks(res)

      res
    end
  end

  def test_performs_request
    builder = build do |b|
      b.adapter Adapter
    end

    req = Faraday::Request.new
    req.body = 'yolo'
    res = builder.build_response(nil, req)
    assert_equal 'yolo', res['X-Body']
    assert_equal 'booya', res.body
  end

  def test_performs_request_with_callbacks
    builder = build do |b|
      b.request Upcaser
      b.response Upcaser
      b.adapter Adapter
    end

    req = Faraday::Request.new
    req.body = 'yolo'
    res = builder.build_response(nil, req)
    assert_equal 'YOLO', res['X-Body']
    assert_equal 'BOOYA', res.body
  end

  def test_initializes_with_empty_callbacks
    builder = self.builder
    assert_equal [], builder.before
    assert_equal [], builder.after
    assert_nil builder.current_adapter
  end

  def test_adds_request_callback
    builder = build do |b|
      b.request Upcaser
    end

    assert_equal 1, builder.before.size
    assert_equal [], builder.after
    assert_nil builder.current_adapter
  end

  def test_adds_response_callback
    builder = build do |b|
      b.response Upcaser
    end

    assert_equal 1, builder.after.size
    assert_equal [], builder.before
    assert_nil builder.current_adapter
  end

  def test_lock
    builder = self.builder
    assert !builder.locked?

    builder.lock!

    assert builder.locked?
  end

  def builder(*args, &block)
    Faraday::CallbackBuilder.new(*args, &block)
  end

  def build(&block)
    b = builder
    b.build(&block)
    b
  end
end

