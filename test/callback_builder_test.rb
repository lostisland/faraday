require File.expand_path('../helper', __FILE__)
Faraday.require_lib 'callback_builder'

class CallbackBuilderTest < Faraday::TestCase
  class Upcaser
    def on_request(req)
      req.body.upcase!
    end

    def on_response(res)
      res.body.upcase!
    end
  end

  class StreamingUpcaser < Upcaser
    def initialize(&block)
      @callback = block
    end

    def on_response_chunk(res, chunk, size)
      @callback.call(chunk.upcase, size)
    end
  end

  class Adapter
    attr_accessor :builder

    def call(req)
      @builder.on_request(req)

      res = if @builder.streaming_callbacks?
        streaming_response(req)
      else
        response(req)
      end

      @builder.on_response(res)

      res
    end

    def response(req)
      Faraday::Response.new :status => 200, :body => 'booya',
        :response_headers => {"Content-Type" => "text/plain",
        'X-Body' => req.body}
    end

    def streaming_response(req)
      res = response(req)

      @builder.on_response_chunk(res, 'boo', 3)
      @builder.on_response_chunk(res, 'ya', 5)

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

  def test_performs_streaming_request
    streamed = []

    builder = build do |b|
      b.request StreamingUpcaser
      b.streaming_response StreamingUpcaser do |chunk, size|
        streamed << [chunk, size]
      end
      b.adapter Adapter
    end

    req = Faraday::Request.new
    req.body = 'yolo'
    res = builder.build_response(nil, req)
    assert_equal 'YOLO', res['X-Body']
    assert_equal [['BOO', 3], ['YA', 5]], streamed
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

  def test_raises_if_lock_without_adapter
    builder = build {}

    assert_raises Faraday::CallbackBuilder::MissingAdapter do
      builder.lock!
    end
  end

  def test_lock
    builder = build { |b| b.adapter(Adapter) }
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

