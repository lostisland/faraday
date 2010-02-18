require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestConnectionApps < Faraday::TestCase
  class TestAdapter
    def initialize(app)
      @app = app
    end

    def call(env)
      [200, {}, env[:test]]
    end
  end

  class TestMiddleWare
    def initialize(app)
      @app = app
    end

    def call(env)
      env[:test] = 'hi'
      @app.call(env)
    end
  end

  def setup
    @conn = Faraday::Connection.new do |b|
      b.use TestMiddleWare
      b.use TestAdapter
    end
  end

  def test_builder_is_built_from_faraday_connection
    assert_kind_of Faraday::Builder, @conn.builder
    assert_equal 3, @conn.builder.handlers.size
  end

  def test_builder_adds_middleware_to_builder_stack
    assert_kind_of TestMiddleWare, @conn.builder.handlers[2].call(nil)
    assert_kind_of TestAdapter,    @conn.builder.handlers[1].call(nil)
  end

  def test_to_app_returns_rack_object
    assert @conn.to_app.respond_to?(:call)
  end
end
