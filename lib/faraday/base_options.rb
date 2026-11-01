# frozen_string_literal: true

module Faraday
  # Abstract base class for Options-like classes.
  #
  # Provides common functionality for nested coercion, deep merging, and duplication.
  # Subclasses define:
  # - +MEMBERS+: Array of attribute names (symbols). Each member needs a public
  #   reader and writer (e.g. +attr_accessor+), which are the only way
  #   attributes are read and written, so subclasses can override them.
  # - +COERCIONS+ (optional): Hash mapping attribute names to either a Class
  #   (coerced with +Class.from(value)+) or a Proc (coerced with +proc.call(value)+).
  #   +nil+ values are never coerced.
  #
  # Keys can be Symbols or Strings. Assigning an unknown key raises
  # +NoMethodError+, like {Options} does. +nil+ values are skipped by
  # {#initialize}, {#update} and {#merge!} so they never overwrite an existing
  # value, while +false+ does. {#to_hash} skips +nil+ values too.
  #
  # @example Creating a subclass
  #   class MyOptions < Faraday::BaseOptions
  #     MEMBERS = [:timeout, :open_timeout].freeze
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
  #     COERCIONS = { uri: ->(value) { Faraday::Utils.URI(value) } }.freeze
  #
  #     attr_accessor :uri
  #   end
  #
  # @see OptionsLike
  class BaseOptions
    include OptionsLike

    MEMBERS = [].freeze
    COERCIONS = {}.freeze

    class << self
      # Create new instance from hash or existing instance.
      #
      # @param value [nil, Hash, OptionsLike, #to_hash] the value to convert
      # @return [BaseOptions] a new instance, a deep copy if the value is
      #   already an instance of this class, so the caller's object is never shared
      # @raise [ArgumentError] if the value is not supported
      #
      # @example
      #   MyOptions.from(nil) # => empty MyOptions instance
      #   MyOptions.from(timeout: 10) # => MyOptions with timeout=10
      #   existing = MyOptions.new(timeout: 10)
      #   MyOptions.from(existing) # => deep copy of existing
      def from(value)
        return value.deep_dup if value.is_a?(self)
        return new if value.nil?
        raise ArgumentError, "unsupported options: #{value.class}" unless value.respond_to?(:to_hash)

        new(value)
      end
    end

    # Initialize a new instance with the given options.
    #
    # @param options [Hash, #to_hash, nil] options to initialize with. Keyword
    #   arguments are passed as a Hash.
    # @raise [NoMethodError] if a key is not a member
    #
    # @example
    #   options = MyOptions.new(timeout: 10, open_timeout: 5)
    #   options = MyOptions.new({ 'timeout' => 10 })
    def initialize(options = nil)
      update(options) if options
    end

    # Update this instance with values from another hash/instance.
    #
    # @param obj [Hash, #to_hash] the values to update with
    # @return [BaseOptions] self
    # @raise [NoMethodError] if a key is not a member
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.update(timeout: 20, open_timeout: 5)
    #   options.timeout # => 20
    def update(obj)
      each_option(obj) { |key, value| write(key, value) }
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

    # Destructive merge.
    #
    # Like {#update}, but Hash and {OptionsLike} values are deep-merged into
    # the existing Hash or {OptionsLike} value of the same member, see
    # {Utils.deep_merge}. Nested values of the receiver are replaced, not mutated.
    #
    # @param obj [Hash, #to_hash] the values to merge
    # @return [BaseOptions] self
    # @raise [NoMethodError] if a key is not a member
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.merge!(timeout: 20)
    #   options.timeout # => 20
    def merge!(obj)
      each_option(obj) { |key, value| write(key, merge_value(public_send(key), value)) }
      self
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
      self.class.new(Utils.deep_dup(to_hash))
    end

    # Convert to a hash.
    #
    # Members that are +nil+ are skipped, and nested {OptionsLike} values are
    # converted to hashes too.
    #
    # @return [Hash] hash representation with symbol keys
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.to_hash # => { timeout: 10 }
    def to_hash
      self.class::MEMBERS.each_with_object({}) do |key, hash|
        value = public_send(key)
        hash[key] = value.is_a?(OptionsLike) ? value.to_hash : value unless value.nil?
      end
    end

    # Inspect the instance.
    #
    # @return [String] human-readable representation
    #
    # @example
    #   options = MyOptions.new(timeout: 10)
    #   options.inspect # => "#<MyOptions timeout=10>"
    def inspect
      pairs = to_hash.map { |key, value| "#{key}=#{value.inspect}" }
      "#<#{self.class} #{pairs.empty? ? '(empty)' : pairs.join(', ')}>"
    end

    private

    # Yields each non-nil pair of +obj+ with a Symbol key.
    def each_option(obj)
      obj = obj.to_hash if obj.respond_to?(:to_hash)
      obj.each do |key, value|
        key = key.to_sym
        unless self.class::MEMBERS.include?(key)
          raise NoMethodError.new("unknown option #{key.inspect} for #{self.class}", :"#{key}=", receiver: self)
        end

        yield key, value unless value.nil?
      end
    end

    def write(key, value)
      public_send(:"#{key}=", coerce(key, value))
    end

    def merge_value(current, value)
      mergeable = (current.is_a?(Hash) || current.is_a?(OptionsLike)) &&
                  (value.is_a?(Hash) || value.is_a?(OptionsLike))
      mergeable ? Utils.deep_merge(current, value.to_hash) : value
    end

    # Coerce a value based on the COERCIONS configuration.
    def coerce(key, value)
      coercion = self.class::COERCIONS[key]
      case coercion
      when Class then coercion.from(value)
      when Proc then coercion.call(value)
      else value
      end
    end
  end
end
