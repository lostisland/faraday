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
      @mutex = @monitor.method(:synchronize)
      @registered = {}
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
      @mutex.call { @registered.update(mapping) }
    end

    # Unregister a previously registered middleware class.
    #
    # @param key [Symbol] key for the registered middleware.
    def unregister(key)
      @mutex.call { @registered.delete(key) }
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

    # Expands the registered value for key until it comes back as a Module,
    # Class, or nil.
    def load_class(key)
      @mutex.call do
        loop do
          klass, register = expand_entry(key)
          return klass unless register
          @registered.update(key => klass)
        end
      end
    end

    def expand_entry(key)
      case value = @registered[key]
      when Module, NilClass
        value
      when Symbol, String
        [@klass.const_get(value), true]
      when Proc
        [value.call, true]
      when Array
        const, path = value
        if (root = @autoload_path) && !root.empty?
          path = "#{root}/#{path}"
        end
        require(path)
        [const, true]
      else
        msg = "unexpected #{@klass} value for #{key.inspect}: #{value.inspect}"
        raise ArgumentError, msg
      end
    end
  end

  # Adds the ability for other modules to register and lookup
  # middleware classes.
  module MiddlewareRegistry
    def self.extended(klass)
      class << klass
        attr_accessor :class_registry
      end
      super
    end

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
    # @example
    #
    #   module Faraday
    #     class Adapter
    #       extend MiddlewareRegistry
    #
    #       register_middleware 'path/to/adapters',
    #         # Lookup constant
    #         some_adapter: SomeAdapter,
    #
    #         # Lookup symbol constant name
    #         # Same as Faraday::Adapter.const_get(:SomeAdapter2)
    #         some_adapter_2: :SomeAdapter2,
    #
    #         # Require lib and then lookup class
    #         # require('some-adapter-3')
    #         # Returns Faraday::Adapter::SomeAdapter3
    #         some_adapter_3: [:SomeAdapter3, 'some-adapter-3']
    #     end
    #   end
    #
    def register_middleware(autoload_path = nil, mapping = nil)
      if class_registry.nil?
        if autoload_path.nil?
          raise ArgumentError, 'needs autoload_path to initialize ClassRegistry'
        end

        self.class_registry = ClassRegistry.new(self, autoload_path, mapping)
        return
      end

      if mapping.nil?
        mapping = autoload_path
        autoload_path = nil
      end

      unless autoload_path.nil? || autoload_path.to_s == @autoload_path
        warn "Cannot change autoload_path of existing #{self}.class_registry"
      end

      class_registry.register(mapping)
    end

    # Unregister a previously registered middleware class.
    #
    # @param key [Symbol] key for the registered middleware.
    def unregister_middleware(key)
      class_registry.unregister(key)
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
    #     extend MiddlewareRegistry
    #     class Adapter
    #       register_middleware('path/to/adapters',
    #         some_adapter: SomeAdapter,
    #       )
    #     end
    #   end
    #
    #   Faraday::Adapter.lookup_middleware(:some_adapter)
    #   # => SomeAdapter
    #
    def lookup_middleware(key)
      class_registry.lookup(key)
    end

    def load_middleware(key)
      warn "Deprecated, use #{self}.lookup_middleware"
      lookup_middleware(key)
    end

    def middleware_mutex
      warn "Deprecated, see #{self}.class_registry"
    end

    def fetch_middleware(_)
      warn "Deprecated, see #{self}.class_registry"
    end
  end
end
