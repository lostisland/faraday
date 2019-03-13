# frozen_string_literal: true

module Faraday
  class RackBuilder
    # Borrowed from ActiveSupport::Dependencies::Reference &
    # ActionDispatch::MiddlewareStack::Middleware
    class Handler
      REGISTRY = Faraday::AdapterRegistry.new

      attr_reader :name

      def initialize(klass, *args, &block)
        @name = klass.to_s
        REGISTRY.set(klass) if klass.respond_to?(:name)
        @args = args
        @block = block
      end

      def klass
        REGISTRY.get(@name)
      end

      def inspect
        @name
      end

      def ==(other)
        if other.is_a? Handler
          name == other.name
        elsif other.respond_to? :name
          klass == other
        else
          @name == other.to_s
        end
      end

      def build(app = nil)
        klass.new(app, *@args, &@block)
      end
    end
  end
end
