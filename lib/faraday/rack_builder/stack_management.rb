# frozen_string_literal: true

module Faraday
  # Helper methods to manage a handlers stack.
  # Used in rack_builder.
  module StackManagement
    # Used to detect missing arguments
    NO_ARGUMENT = Object.new

    # Error raised when trying to modify the stack after calling `lock!`
    class StackLocked < RuntimeError; end

    def build(options = {})
      raise_if_locked
      @handlers.clear unless options[:keep]
      yield(self) if block_given?
      adapter(Faraday.default_adapter) unless @adapter
    end

    def use(klass, *args, &block)
      if klass.is_a? Symbol
        use_symbol(Faraday::Middleware, klass, *args, &block)
      else
        raise_if_locked
        raise_if_adapter(klass)
        @handlers << self.class::Handler.new(klass, *args, &block)
      end
    end

    def request(key, *args, &block)
      use_symbol(Faraday::Request, key, *args, &block)
    end

    def response(key, *args, &block)
      use_symbol(Faraday::Response, key, *args, &block)
    end

    def adapter(klass = NO_ARGUMENT, *args, &block)
      return @adapter if klass == NO_ARGUMENT

      klass = Faraday::Adapter.lookup_middleware(klass) if klass.is_a?(Symbol)
      @adapter = self.class::Handler.new(klass, *args, &block)
    end

    ## methods to push onto the various positions in the stack:

    def insert(index, *args, &block)
      raise_if_locked
      index = assert_index(index)
      handler = self.class::Handler.new(*args, &block)
      @handlers.insert(index, handler)
    end

    alias insert_before insert

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

    LOCK_ERR = "can't modify middleware stack after making a request"

    def raise_if_locked
      raise StackLocked, LOCK_ERR if locked?
    end

    def raise_if_adapter(klass)
      return unless is_adapter?(klass)

      raise 'Adapter should be set using the `adapter` method, not `use`'
    end

    def adapter_set?
      !@adapter.nil?
    end

    def is_adapter?(klass) # rubocop:disable Naming/PredicateName
      klass.ancestors.include?(Faraday::Adapter)
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
