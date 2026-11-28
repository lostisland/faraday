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

    # The attribute names, in order. Subclasses override it.
    MEMBERS = [].freeze

    # The coercion of each attribute that has one. Subclasses can override it.
    COERCIONS = {}.freeze

    class << self
      # The member names, like +members+ of the legacy {Options} Structs.
      # Gems use it to check what this Faraday version supports, e.g.
      # +Faraday::SSLOptions.members.include?(:verify_hostname)+.
      #
      # @deprecated Slated for removal in Faraday 3.0, use +MEMBERS+, or
      #   +method_defined?+ to check for a member. There is no runtime warning yet.
      # @return [Array<Symbol>] a new Array, so the caller can change it
      def members
        self::MEMBERS.dup
      end

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

      # The writer method of each member. Memoized because building it with
      # interpolation allocates a String on every write.
      #
      # @api private
      # @return [Hash{Symbol => Symbol}] member name to writer method name
      def writer_symbols
        @writer_symbols ||= self::MEMBERS.to_h { |key| [key, :"#{key}="] }.freeze
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
      standard_hooks = self.class.instance_method(:initialize).owner == BaseOptions &&
                       ::Kernel.instance_method(:method).bind_call(self, :to_hash).owner == BaseOptions &&
                       self.class.method(:new).owner == Class
      return self.class.new(Utils.deep_dup(to_hash)) unless standard_hooks

      copy = self.class.new
      self.class::MEMBERS.each do |key|
        value = public_send(key)
        next if value.nil?

        value = value.to_hash if value.is_a?(OptionsLike)
        copy.send(:write, key, Utils.deep_dup(value))
      end
      copy
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

    # Whether no member is set, like +empty?+ of the legacy {Options}
    # Structs, e.g. +conn.ssl.empty?+. A member set to +false+ counts as set.
    #
    # @deprecated Slated for removal in Faraday 3.0, use +to_hash.empty?+
    #   instead. There is no runtime warning yet.
    # @return [Boolean] true if every member is +nil+
    def empty?
      self.class::MEMBERS.all? { |key| public_send(key).nil? }
    end

    # Every member and its value, +nil+ included, like +to_h+ of the legacy
    # {Options} Structs. Nested options stay objects. {#to_hash} leaves out
    # +nil+ values and converts nested options to hashes.
    #
    # @deprecated Slated for removal in Faraday 3.0, use {#to_hash} instead.
    #   There is no runtime warning yet.
    # @yield [key, value] optional, returns the pair to use, like +Hash#to_h+
    # @return [Hash] a Hash with symbol keys
    def to_h(&block)
      hash = self.class::MEMBERS.to_h { |key| [key, public_send(key)] }
      block ? hash.to_h(&block) : hash
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
      writer = self.class.writer_symbols[key.to_sym] if key.respond_to?(:to_sym)
      public_send(writer || :"#{key}=", coerce(key, value))
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
