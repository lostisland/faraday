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

  before do
    @conn = Faraday::Connection.new do |b|
      b.use TestMiddleWare
      b.use TestAdapter
    end
  end

  describe "#builder" do
    it "is built from Faraday::Connection constructor" do
      assert_kind_of Faraday::Builder, @conn.builder
      assert_equal 3, @conn.builder.handlers.size
    end

    it "adds middleware to the Builder stack" do
      assert_kind_of TestMiddleWare, @conn.builder.handlers[2].call(nil)
      assert_kind_of TestAdapter,    @conn.builder.handlers[1].call(nil)
    end
  end

  describe "#to_app" do
    it "returns rack-compatible object" do
      assert @conn.to_app.respond_to?(:call)
    end
  end
end
