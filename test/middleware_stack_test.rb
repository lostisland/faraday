require File.expand_path('../helper', __FILE__)

class MiddlewareStackTest < Faraday::TestCase
  # mock handler classes
  class Handler < Struct.new(:app)
    def call(env)
      (env[:request_headers]['X-Middleware'] ||= '') << ":#{self.class.name.split('::').last}"
      app.call(env)
    end
  end
  class Apple < Handler; end
  class Orange < Handler; end
  class Banana < Handler; end

  class Broken < Faraday::Middleware
    dependency 'zomg/i_dont/exist'
  end

  def setup
    @conn = Faraday::Connection.new
    @builder = @conn.builder
  end

  def test_sets_default_adapter_if_none_set
    default_middleware = Faraday::Request.lookup_middleware :url_encoded
    default_adapter_klass = Faraday::Adapter.lookup_middleware Faraday.default_adapter
    assert @builder[0] == default_middleware
    assert @builder[1] == default_adapter_klass
  end

  def test_allows_rebuilding
    build_stack Apple
    build_stack Orange
    assert_handlers %w[Orange]
  end

  def test_allows_extending
    build_stack Apple
    @conn.use Orange
    assert_handlers %w[Apple Orange]
  end

  def test_builder_is_passed_to_new_faraday_connection
    new_conn = Faraday::Connection.new :builder => @builder
    assert_equal @builder, new_conn.builder
  end

  def test_insert_before
    build_stack Apple, Orange
    @builder.insert_before Apple, Banana
    assert_handlers %w[Banana Apple Orange]
  end

  def test_insert_after
    build_stack Apple, Orange
    @builder.insert_after Apple, Banana
    assert_handlers %w[Apple Banana Orange]
  end

  def test_swap_handlers
    build_stack Apple, Orange
    @builder.swap Apple, Banana
    assert_handlers %w[Banana Orange]
  end

  def test_delete_handler
    build_stack Apple, Orange
    @builder.delete Apple
    assert_handlers %w[Orange]
  end

  def test_stack_is_locked_after_making_requests
    build_stack Apple
    assert !@builder.locked?
    @conn.get('/')
    assert @builder.locked?

    assert_raises Faraday::RackBuilder::StackLocked do
      @conn.use Orange
    end
  end

  def test_duped_stack_is_unlocked
    build_stack Apple
    assert !@builder.locked?
    @builder.lock!
    assert @builder.locked?

    duped_connection = @conn.dup
    assert_equal @builder, duped_connection.builder
    assert !duped_connection.builder.locked?
  end

  def test_handler_comparison
    build_stack Apple
    assert_equal @builder.handlers.first, Apple
    assert_equal @builder.handlers[0,1], [Apple]
    assert_equal @builder.handlers.first, Faraday::RackBuilder::Handler.new(Apple)
  end

  def test_unregistered_symbol
    err = assert_raises(Faraday::Error){ build_stack :apple }
    assert_equal ":apple is not registered on Faraday::Middleware", err.message
  end

  def test_registered_symbol
    Faraday::Middleware.register_middleware :apple => Apple
    begin
      build_stack :apple
      assert_handlers %w[Apple]
    ensure
      unregister_middleware Faraday::Middleware, :apple
    end
  end

  def test_registered_symbol_with_proc
    Faraday::Middleware.register_middleware :apple => lambda { Apple }
    begin
      build_stack :apple
      assert_handlers %w[Apple]
    ensure
      unregister_middleware Faraday::Middleware, :apple
    end
  end

  def test_registered_symbol_with_array
    Faraday::Middleware.register_middleware File.expand_path("..", __FILE__),
      :strawberry => [lambda { Strawberry }, 'strawberry']
    begin
      build_stack :strawberry
      assert_handlers %w[Strawberry]
    ensure
      unregister_middleware Faraday::Middleware, :strawberry
    end
  end

  def test_missing_dependencies
    build_stack Broken
    err = assert_raises RuntimeError do
      @conn.get('/')
    end
    assert_match "missing dependency for MiddlewareStackTest::Broken: ", err.message
    assert_match "zomg/i_dont/exist", err.message
  end

  private

  # make a stack with test adapter that reflects the order of middleware
  def build_stack(*handlers)
    @builder.build do |b|
      handlers.each { |handler| b.use(*handler) }
      yield(b) if block_given?

      b.adapter :test do |stub|
        stub.get '/' do |env|
          # echo the "X-Middleware" request header in the body
          [200, {}, env[:request_headers]['X-Middleware'].to_s]
        end
      end
    end
  end

  def assert_handlers(list)
    echoed_list = @conn.get('/').body.to_s.split(':')
    echoed_list.shift if echoed_list.first == ''
    assert_equal list, echoed_list
  end

  def unregister_middleware(component, key)
    # TODO: unregister API?
    component.instance_variable_get('@registered_middleware').delete(key)
  end
end
