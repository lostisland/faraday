# frozen_string_literal: true

require 'monitor'

module Faraday
  # ClassRegistry tracks potential middleware dependencies for a given parent
  # class. These potential dependencies are lazily required upon first access
  # during runtime.
  class ClassRegistry
    attr_reader :autoload_path

    def initialize(klass, autoload_path, mapping = nil)
      @klass = klass
      @autoload_path = autoload_path.to_s.freeze
      @monitor = Monitor.new
      @registered_middleware = {}
      register(mapping) if mapping
    end

    # Register middleware class(es) on the current module.
    #
    # @param mapping [Hash{
    #          Symbol => Module,
    #          Symbol => Array<Module, Symbol, String>,
    #        }] Middleware mapping from a lookup symbol to a reference to the
    #        middleware.
    #        Classes can be expressed as:
    #          - a fully qualified constant
    #          - a Symbol
    #          - a Proc that will be lazily called to return the former
    #          - an array is given, its first element is the constant or symbol,
    #            and its second is a file to `require`.
    # @return [void]
    #
    # @example
    #
    #   # builds a registry for Faraday::Adapter, lazily loading from
    #   # 'path/to/adapters/*.rb'
    #   cr = ClassRegistry.new(Faraday::Adapter, 'path/to/adapters')
    #   cr.register(
    #     # Lookup constant
    #     some_adapter: SomeAdapter,
    #
    #     # Lookup symbol constant name
    #     # Same as Faraday::Adapter.const_get(:SomeAdapter2)
    #     some_adapter_2: :SomeAdapter2,
    #
    #     # Require lib and then lookup class
    #     # require('some-adapter-3')
    #     # Returns Faraday::Adapter::SomeAdapter3
    #     some_adapter_3: [:SomeAdapter3, 'some-adapter-3']
    #   )
    #
    def register(mapping)
      @monitor.synchronize { @registered_middleware.update(mapping) }
    end

    # Unregister a previously registered middleware class.
    #
    # @param key [Symbol] key for the registered middleware.
    def unregister(key)
      @registered_middleware.delete(key)
    end

    # Lookup middleware class with a registered Symbol shortcut.
    #
    # @param key [Symbol] key for the registered middleware.
    # @return [Class] a middleware Class.
    # @raise [Faraday::Error] if given key is not registered
    #
    # @example
    #
    #   cr = ClassRegistry.new(Faraday::Adapter, .path/to/adapters.)
    #   cr.register(some_adapter: SomeAdapter)
    #
    #   cr.lookup(:some_adapter)
    #   # => SomeAdapter
    #
    def lookup(key)
      load_class(key) ||
        raise(Faraday::Error,
              "#{key.inspect} is not registered on #{@klass}")
    end

    private

    def load_class(key)
      case value = @registered_middleware[key]
      when Module, NilClass
        return value
      when Symbol, String
        register(key => @klass.const_get(value))
      when Proc
        register(key => value.call)
      when Array
        const, path = value
        if (root = @autoload_path) && !root.empty?
          path = "#{root}/#{path}"
        end
        require(path)
        register(key => const)
      else
        msg = "unexpected #{@klass} value for #{key.inspect}: #{value.inspect}"
        raise ArgumentError, msg
      end

      load_class(key)
    end
  end

  # Adds the ability for other modules to register and lookup
  # middleware classes.
  module MiddlewareRegistry
    # Register middleware class(es) on the current module.
    #
    # @param autoload_path [String] Middleware autoload path
    # @param mapping [Hash{
    #          Symbol => Module,
    #          Symbol => Array<Module, Symbol, String>,
    #        }] Middleware mapping from a lookup symbol to a reference to the
    #        middleware.
    #        Classes can be expressed as:
    #          - a fully qualified constant
    #          - a Symbol
    #          - a Proc that will be lazily called to return the former
    #          - an array is given, its first element is the constant or symbol,
    #            and its second is a file to `require`.
    # @return [void]
    #
    # @example Lookup by a constant
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :foo returns Faraday::Whatever::Foo.
    #       register_middleware foo: Foo
    #     end
    #   end
    #
    # @example Lookup by a symbol
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :bar returns
    #       # Faraday::Whatever.const_get(:Bar)
    #       register_middleware bar: :Bar
    #     end
    #   end
    #
    # @example Lookup by a symbol and string in an array
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :baz requires 'baz' and returns
    #       # Faraday::Whatever.const_get(:Baz)
    #       register_middleware baz: [:Baz, 'baz']
    #     end
    #   end
    #
    def register_middleware(autoload_path = nil, mapping = nil)
      if mapping.nil?
        mapping = autoload_path
        autoload_path = nil
      end
      middleware_mutex do
        @middleware_autoload_path = autoload_path if autoload_path
        (@registered_middleware ||= {}).update(mapping)
      end
    end

    # Unregister a previously registered middleware class.
    #
    # @param key [Symbol] key for the registered middleware.
    def unregister_middleware(key)
      @registered_middleware.delete(key)
    end

    # Lookup middleware class with a registered Symbol shortcut.
    #
    # @param key [Symbol] key for the registered middleware.
    # @return [Class] a middleware Class.
    # @raise [Faraday::Error] if given key is not registered
    #
    # @example
    #
    #   module Faraday
    #     class Whatever
    #       register_middleware foo: Foo
    #     end
    #   end
    #
    #   Faraday::Whatever.lookup_middleware(:foo)
    #   # => Faraday::Whatever::Foo
    #
    def lookup_middleware(key)
      load_middleware(key) ||
        raise(Faraday::Error, "#{key.inspect} is not registered on #{self}")
    end

    def middleware_mutex(&block)
      @middleware_mutex ||= Monitor.new
      @middleware_mutex.synchronize(&block)
    end

    def fetch_middleware(key)
      defined?(@registered_middleware) && @registered_middleware[key]
    end

    def load_middleware(key)
      value = fetch_middleware(key)
      case value
      when Module
        value
      when Symbol, String
        middleware_mutex do
          @registered_middleware[key] = const_get(value)
        end
      when Proc
        middleware_mutex do
          @registered_middleware[key] = value.call
        end
      when Array
        middleware_mutex do
          const, path = value
          if (root = @middleware_autoload_path)
            path = "#{root}/#{path}"
          end
          require(path)
          @registered_middleware[key] = const
        end
        load_middleware(key)
      end
    end
  end
end
