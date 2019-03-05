# frozen_string_literal: true

require 'monitor'

module Faraday
  # AdapterRegistry registers adapter class names so they can be looked up by a
  # String or Symbol name.
  class AdapterRegistry
    def initialize
      @lock = Monitor.new
      @constants = nil
    end

    def get(name)
      klass = @constants && @constants[name]
      return klass if klass

      klass =
        if name.respond_to?(:constantize)
          name.constantize
        else
          Object.const_get(name)
        end

      set(klass, name)

      klass
    end

    def set(klass, name = nil)
      name ||= klass.to_s
      @lock.synchronize do
        @constants ||= {}
        @constants[name] = klass
      end
    end
  end
end
