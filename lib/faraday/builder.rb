module Faraday
  # Possibly going to extend this a bit.
  #
  # Faraday::Connection.new(:url => 'http://sushi.com') do |b|
  #   b.request  :yajl     # Faraday::Request::Yajl
  #   b.adapter  :logger   # Faraday::Adapter::Logger
  #   b.response :yajl     # Faraday::Response::Yajl
  # end
  class Builder
    attr_accessor :handlers

    def self.create
      new { |builder| yield builder }
    end

    def self.inner_app
      lambda do |env|
        env[:parallel_manager] ? env[:response] : env[:response].finish(env)
      end
    end

    # borrowed from ActiveSupport::Dependencies::Reference &
    # ActionDispatch::MiddlewareStack::Middleware
    class Handler
      @@constants = Hash.new { |h, k|
        h[k] = k.respond_to?(:constantize) ? k.constantize : Object.const_get(k)
      }

      attr_reader :name

      def initialize(klass, *args, &block)
        @name = klass.to_s
        @@constants[@name] = klass if klass.respond_to?(:name)
        @args, @block = args, block
      end

      def klass() @@constants[@name] end
      def inspect() @name end

      def ==(other)
        if other.respond_to? :name
          klass == other
        else
          @name == other.to_s
        end
      end

      def build(app)
        klass.new(app, *@args, &@block)
      end
    end

    def initialize(handlers = [])
      @handlers = handlers
      @inner_app = self.class.inner_app
      build(&Proc.new) if block_given?
    end

    def build(options = {})
      @handlers.clear unless options[:keep]
      yield self if block_given?
    end

    def run(app = nil)
      @inner_app = app || Proc.new
    end

    def [](idx)
      @handlers[idx]
    end

    def ==(other)
      other.is_a?(self.class) && @handlers == other.handlers
    end

    def dup
      self.class.new(@handlers.dup)
    end

    def to_app
      # use at least an adapter so the stack isn't a no-op
      self.adapter Faraday.default_adapter if @handlers.empty?
      # last added handler should be the deepest, closest to the inner app
      @handlers.reverse.inject(@inner_app) { |app, handler| handler.build(app) }
    end

    def use(klass, *args)
      block = block_given? ? Proc.new : nil
      @handlers << self.class::Handler.new(klass, *args, &block)
    end

    def request(key, *args)
      block = block_given? ? Proc.new : nil
      use_symbol(Faraday::Request, key, *args, &block)
    end

    def response(key, *args)
      block = block_given? ? Proc.new : nil
      use_symbol(Faraday::Response, key, *args, &block)
    end

    def adapter(key, *args)
      block = block_given? ? Proc.new : nil
      use_symbol(Faraday::Adapter, key, *args, &block)
    end

    ## methods to push onto the various positions in the stack:

    def insert(index, *args, &block)
      index = assert_index(index, :before)
      handler = self.class::Handler.new(*args, &block)
      @handlers.insert(index, handler)
    end

    alias_method :insert_before, :insert

    def insert_after(index, *args, &block)
      index = assert_index(index, :after)
      insert(index + 1, *args, &block)
    end

    def swap(target, *args, &block)
      insert_before(target, *args, &block)
      delete(target)
    end

    def delete(handler)
      @handlers.delete(handler)
    end

    private

    def use_symbol(mod, key, *args)
      block = block_given? ? Proc.new : nil
      use(mod.lookup_module(key), *args, &block)
    end

    def assert_index(index, where)
      idx = index.is_a?(Integer) ? index : @handlers.index(index)
      raise "No such handler to insert #{where}: #{index.inspect}" unless idx
      idx
    end
  end
end
