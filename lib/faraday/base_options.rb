# frozen_string_literal: true

module Faraday
  # Abstract base class for Options-like classes.
  #
  # Provides common functionality for nested coercion, deep merging, and duplication.
  # Subclasses must define:
  # - +MEMBERS+: Array of attribute names (symbols)
  # - +COERCIONS+: Hash mapping attribute names to coercion classes
  #
  # @example Creating a subclass
  #   class MyOptions < Faraday::BaseOptions
  #     MEMBERS = [:timeout, :open_timeout].freeze
  #     COERCIONS = {}.freeze
  #
  #     attr_accessor :timeout, :open_timeout
  #   end
  #
  #   options = MyOptions.new(timeout: 10)
  #   options.timeout # => 10
  #
  # @example With nested coercion
  #   class ProxyOptions < Faraday::BaseOptions
  #     MEMBERS = [:uri].freeze
  #     COERCIONS = { uri: URI }.freeze
  #
  #     attr_accessor :uri
  #   end
  #
  # @see OptionsLike
  class BaseOptions
    include OptionsLike

    # Subclasses must define:
    # - MEMBERS: Array of attribute names (symbols)
    # - COERCIONS: Hash mapping attribute names to coercion classes

    class << self
      # Create new instance from hash or existing instance.
      #
      # @param value [nil, Hash, BaseOptions] the value to convert
      # @return [BaseOptions] a new instance or the value itself if already correct type
      #
      # @example
      #   MyOptions.from(nil) # => empty MyOptions instance
      #   MyOptions.from(timeout: 10) # => MyOptions with timeout=10
      #   existing = MyOptions.new(timeout: 10)
      #   MyOptions.from(existing) # => returns existing (same instance)
      def from(value)
        return value if value.is_a?(self)
        return new if value.nil?

        new(value)
      end
    end

    # Initialize a new instance with the given options.
    #
    # @param options_hash [Hash, #to_hash, nil] options to initialize with as positional arg
    # @param options [Hash] options to initialize with as keyword args
    # @return [BaseOptions] self
    #
    # @example
    #   options = MyOptions.new(timeout: 10, open_timeout: 5)
    #   options = MyOptions.new({ timeout: 10 })
    def initialize(options_hash = nil, **options)
      # Merge positional and keyword arguments
      if options_hash
        options_hash = options_hash.to_hash if options_hash.respond_to?(:to_hash)
        options = options_hash.merge(options)
      end

      self.class::MEMBERS.each do |key|
        value = options[key] || options[key.to_s]
        value = coerce(key, value)
        instance_variable_set(:"@#{key}", value)
      end
    end

    # Update this instance with values from another hash/instance.
    #
    # @param obj [Hash, #to_hash] the values to update with
    # @return [BaseOptions] self
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.update(timeout: 20, open_timeout: 5)
    #   options.timeout # => 20
    def update(obj)
      obj = obj.to_hash if obj.respond_to?(:to_hash)
      obj.each do |key, value|
        key = key.to_sym
        if self.class::MEMBERS.include?(key)
          value = coerce(key, value)
          instance_variable_set(:"@#{key}", value)
        end
      end
      self
    end

    # Non-destructive merge.
    #
    # Creates a deep copy and merges the given hash/instance into it.
    #
    # @param obj [Hash, #to_hash] the values to merge
    # @return [BaseOptions] a new instance with merged values
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   new_options = options.merge(timeout: 20)
    #   options.timeout # => 10 (unchanged)
    #   new_options.timeout # => 20
    def merge(obj)
      deep_dup.merge!(obj)
    end

    # Destructive merge using {Utils.deep_merge!}.
    #
    # @param obj [Hash, #to_hash] the values to merge
    # @return [BaseOptions] self
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.merge!(timeout: 20)
    #   options.timeout # => 20
    def merge!(obj)
      obj = obj.to_hash if obj.respond_to?(:to_hash)
      hash = to_hash
      Utils.deep_merge!(hash, obj)
      update(hash)
    end

    # Create a deep duplicate of this instance.
    #
    # @return [BaseOptions] a new instance with deeply duplicated values
    #
    # @example
    #   original = MyOptions.new(timeout: 10)
    #   copy = original.deep_dup
    #   copy.timeout = 20
    #   original.timeout # => 10 (unchanged)
    def deep_dup
      self.class.new(
        self.class::MEMBERS.each_with_object({}) do |key, hash|
          value = instance_variable_get(:"@#{key}")
          hash[key] = Utils.deep_dup(value)
        end
      )
    end

    # Convert to a hash.
    #
    # @return [Hash] hash representation with symbol keys
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.to_hash # => { timeout: 10 }
    def to_hash
      self.class::MEMBERS.each_with_object({}) do |key, hash|
        hash[key] = instance_variable_get(:"@#{key}")
      end
    end

    # Inspect the instance.
    #
    # @return [String] human-readable representation
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.inspect # => "#<MyOptions {:timeout=>10}>"
    def inspect
      "#<#{self.class} #{to_hash.inspect}>"
    end

    private

    # Coerce a value based on the COERCIONS configuration.
    #
    # @param key [Symbol] the attribute name
    # @param value [Object] the value to coerce
    # @return [Object] the coerced value or original if no coercion defined
    def coerce(key, value)
      coercion = self.class::COERCIONS[key]
      return value unless coercion
      return value if value.nil?
      return value if value.is_a?(coercion)

      coercion.from(value)
    end
  end
end
