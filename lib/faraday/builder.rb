module Faraday
  # Possibly going to extend this a bit.
  #
  # Faraday::Connection.new(:url => 'http://sushi.com') do |builder|
  #   builder.request  :url_encoded  # Faraday::Request::UrlEncoded
  #   builder.adapter  :net_http     # Faraday::Adapter::NetHttp
  # end
  class Builder
    attr_accessor :handlers

    # Error raised when trying to modify the stack after calling `lock!`
    class StackLocked < RuntimeError; end

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
        if other.is_a? Handler
          self.name == other.name
        elsif other.respond_to? :name
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
      if block_given?
        build(&Proc.new)
      elsif @handlers.empty?
        # default stack, if nothing else is configured
        self.request :url_encoded
        self.adapter Faraday.default_adapter
      end
    end

    def build(options = {})
      raise_if_locked
      @handlers.clear unless options[:keep]
      yield self if block_given?
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

    def to_app(inner_app)
      # last added handler is the deepest and thus closest to the inner app
      @handlers.reverse.inject(inner_app) { |app, handler| handler.build(app) }
    end

    # Locks the middleware stack to ensure no further modifications are possible.
    def lock!
      @handlers.freeze
    end

    def locked?
      @handlers.frozen?
    end

    def use(klass, *args, &block)
      if klass.is_a? Symbol
        use_symbol(Faraday::Middleware, klass, *args, &block)
      else
        raise_if_locked
        @handlers << self.class::Handler.new(klass, *args, &block)
      end
    end

    def request(key, *args, &block)
      use_symbol(Faraday::Request, key, *args, &block)
    end

    def response(key, *args, &block)
      use_symbol(Faraday::Response, key, *args, &block)
    end

    def adapter(key, *args, &block)
      use_symbol(Faraday::Adapter, key, *args, &block)
    end

    ## methods to push onto the various positions in the stack:

    def insert(index, *args, &block)
      raise_if_locked
      index = assert_index(index)
      handler = self.class::Handler.new(*args, &block)
      @handlers.insert(index, handler)
    end

    alias_method :insert_before, :insert

    def insert_after(index, *args, &block)
      index = assert_index(index)
      insert(index + 1, *args, &block)
    end

    def swap(index, *args, &block)
      raise_if_locked
      index = assert_index(index)
      @handlers.delete_at(index)
      insert(index, *args, &block)
    end

    def delete(handler)
      raise_if_locked
      @handlers.delete(handler)
    end

    private

    def raise_if_locked
      raise StackLocked, "can't modify middleware stack after making a request" if locked?
    end

    def use_symbol(mod, key, *args, &block)
      use(mod.lookup_middleware(key), *args, &block)
    end

    def assert_index(index)
      idx = index.is_a?(Integer) ? index : @handlers.index(index)
      raise "No such handler: #{index.inspect}" unless idx
      idx
    end
  end
end
