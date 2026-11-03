# frozen_string_literal: true

module Faraday
  # The Struct-style API of the legacy {Options}, for the {BaseOptions}
  # subclasses converted from it ({ProxyOptions}, {RequestOptions},
  # {SSLOptions}).
  #
  # Adapters and middleware are written against it, e.g.
  # +env[:request][:timeout]+, +env[:ssl].fetch(:verify, true)+ or
  # +env[:request][:proxy][:uri]+, and official adapters support every
  # Faraday 2.x, so it is kept for the whole 2.x series with the legacy
  # semantics. Reads and writes go through the public accessors of the members.
  #
  # @deprecated All of this module is slated for removal in Faraday 3.0, use
  #   the accessors of the options, {BaseOptions#to_hash} and
  #   {BaseOptions#update} instead. There is no runtime warning yet.
  #
  # Besides the Struct-style methods, it restores the behaviour the legacy
  # {Options} had and {BaseOptions} does not:
  # - Struct-style construction: +new(true)+ sets the first member, and
  #   +new(nil)+, +from(false)+ build an empty instance;
  # - {#to_hash} keeps nested options as they are, and {#inspect} skips +false+;
  # - Hash values are copied (shallowly) when assigned, {ClassMethods.from} and {#deep_dup}
  #   of an instance share nested options, and {#merge!} only merges members
  #   coerced with a Class (replacing every other value);
  # - +is_a?(Faraday::Options)+ and +Faraday::Options === options+ hold;
  # - {Utils.deep_merge!} writes +nil+ values.
  #
  # It must not be used by new options classes.
  #
  # @api private
  module StructCompat
    include Enumerable

    # Lets +Faraday::Options === options+ match the instances of the classes
    # including {StructCompat}, e.g. in +case+ statements.
    #
    # @api private
    module OptionsMatcher
      def ===(other)
        super || (equal?(Options) && other.is_a?(StructCompat))
      end
    end

    # @api private
    module ClassMethods
      # @return [Array<Symbol>] the members
      def members
        self::MEMBERS.dup
      end

      # Like {BaseOptions.from}, but a falsy value builds an empty instance and
      # an instance is copied shallowly: nested options are shared.
      def from(value)
        return new.update(value) if value.is_a?(self)

        value ? super : new
      end
    end

    def self.included(base)
      super
      base.extend(ClassMethods)
    end

    # Besides the options Hash of {BaseOptions#initialize}, it accepts the
    # members as positional arguments, in order, without any coercion.
    #
    # @example
    #   SSLOptions.new(verify: false)
    #   SSLOptions.new(false)
    # @raise [ArgumentError] if there are more arguments than members
    def initialize(*args, **kwargs)
      args << kwargs unless kwargs.empty?
      if args.empty?
        super()
      elsif args.size == 1 && (args.first.nil? || args.first.respond_to?(:to_hash))
        super(args.first)
      else
        raise ArgumentError, 'struct size differs' if args.size > self.class::MEMBERS.size

        args.each_with_index { |value, index| public_send(:"#{self.class::MEMBERS[index]}=", value) }
      end
    end

    # @return [Array<Symbol>] the members
    def members
      self.class.members
    end

    # @param key [Symbol, String] a member
    # @return [Object] the value of the member
    # @raise [NameError] if +key+ is not a member
    def [](key)
      public_send(member_for(key))
    end

    # Writes a member, without coercion.
    #
    # @param key [Symbol, String, Integer] a member, or its position
    # @param value [Object] the new value of the member
    # @raise [NameError] if +key+ is not a member
    # @raise [IndexError] if the position is out of range
    def []=(key, value)
      member = key.is_a?(Integer) ? member_at!(key) : member_for(key)
      public_send(:"#{member}=", value)
    end

    # Returns the value of a member. A member that is not set (+nil+) is set to
    # the default, or to the block value, and that value is returned.
    #
    # @param key [Symbol, String] a member
    # @param args [Array] the optional default value
    # @return [Object] the value of the member
    # @raise [KeyError] if the member is not set and there is no default
    def fetch(key, *args)
      unless members.include?(key.to_sym) && !public_send(key).nil?
        key_setter = :"#{key}="
        if !args.empty?
          public_send(key_setter, args.first)
        elsif block_given?
          public_send(key_setter, yield(key))
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
      public_send(key)
    end

    # @param keys [Array<Symbol, String>] members
    # @return [Array<Object>] the values of the members
    # @raise [NoMethodError] if a key is not a member
    def values_at(*keys)
      keys.map { |key| public_send(reader_for(key)) }
    end

    # @return [Array<Object>] the values of all the members, set or not
    def values
      members.map { |key| public_send(key) }
    end
    alias to_a values
    alias deconstruct values

    # @return [Array<Symbol>] the members that are set
    def keys
      members.reject { |key| public_send(key).nil? }
    end

    # @return [Integer] the number of members, set or not
    def size
      members.size
    end
    alias length size

    # @return [Hash] all the members, set or not, unlike {BaseOptions#to_hash}
    def to_h(&block)
      hash = members.to_h { |key| [key, public_send(key)] }
      block ? hash.to_h(&block) : hash
    end

    # @param keys [Array<Symbol>, nil] the members to select, all by default
    # @return [Hash] the members for pattern matching
    def deconstruct_keys(keys)
      keys ? to_h.slice(*keys) : to_h
    end

    # Unlike {BaseOptions#to_hash}, nested options are kept as they are.
    #
    # @return [Hash] the members that are set
    def to_hash
      members.each_with_object({}) do |key, hash|
        value = public_send(key)
        hash[key] = value unless value.nil?
      end
    end

    # @return [Boolean] true if no member is set
    def empty?
      keys.empty?
    end

    # Yields the name and the value of all the members, set or not.
    def each
      return to_enum(:each) unless block_given?

      members.each { |key| yield(key, public_send(key)) }
    end

    # Yields the name and the value of all the members as a pair, like
    # +Struct#each_pair+.
    def each_pair
      return to_enum(:each_pair) unless block_given?

      members.each { |key| yield([key, public_send(key)]) }
    end

    # Yields the name of the members that are set.
    def each_key(&block)
      return to_enum(:each_key) unless block

      keys.each(&block)
    end

    # Yields the value of all the members, set or not.
    def each_value(&block)
      return to_enum(:each_value) unless block

      values.each(&block)
    end

    # @return [Array<Object>] the values of all the members the block is true for
    def select(&block)
      return to_enum(:select) unless block

      values.select(&block)
    end
    alias filter select

    # @param key [Symbol] a member
    # @return [Boolean] true if the member is set
    def key?(key)
      keys.include?(key)
    end
    alias has_key? key?

    # @param value [Object]
    # @return [Boolean] true if a member has the value
    def value?(value)
      values.include?(value)
    end
    alias has_value? value?

    # Unsets a member.
    #
    # @param key [Symbol, String] a member
    # @return [Object] the previous value of the member
    # @raise [NoMethodError] if +key+ is not a member
    def delete(key)
      reader = reader_for(key)
      value = public_send(reader)
      public_send(:"#{reader}=", nil)
      value
    end

    # Unsets all the members.
    def clear
      members.each { |key| delete(key) }
    end

    # @return [Object, nil] the nested value, see +Hash#dig+. It is +nil+ if
    #   the first key is not a member.
    def dig(key, *rest)
      member = key.is_a?(Integer) ? members[key] : (key.to_sym if key.respond_to?(:to_sym))
      value = public_send(member) if members.include?(member)
      rest.empty? || value.nil? ? value : value.dig(*rest)
    end

    # @return [Set<Symbol>] the members that are set
    def symbolized_key_set
      Set.new(keys)
    end

    # @return [Boolean] true if +other+ is of the same class with equal members
    def ==(other)
      other.class == self.class && other.values == values
    end

    def eql?(other)
      other.class == self.class && other.values.eql?(values)
    end

    def hash
      [self.class, values].hash
    end

    # A shallow copy of the nested options, like the legacy {Options#deep_dup}:
    # it shares them with the receiver.
    def deep_dup
      self.class.from(self)
    end

    # Like {BaseOptions#merge!}, but only the members coerced with a Class
    # (nested options) are merged with the Hash or {OptionsLike} given, like the
    # legacy {Options#merge!}. Any other value replaces the current one, and is
    # not copied.
    def merge!(other)
      each_option(other) do |key, value|
        coercion = self.class::COERCIONS[key]
        current = public_send(key)
        mergeable = coercion.is_a?(Class) && current.is_a?(OptionsLike) &&
                    (value.is_a?(Hash) || value.is_a?(OptionsLike))
        value = current.merge(value) if mergeable
        coercion ? write(key, value) : public_send(:"#{key}=", value)
      end
      self
    end

    # Unlike {BaseOptions#inspect}, it skips the members that are +false+ too
    # and shows nested options as they are.
    def inspect
      pairs = members.filter_map do |key|
        value = public_send(key)
        "#{key}=#{value.inspect}" if value
      end
      "#<#{self.class} #{pairs.empty? ? '(empty)' : pairs.join(', ')}>"
    end

    # Like +Struct#to_s+, it lists all the members.
    def to_s
      pairs = members.map { |key| "#{key}=#{public_send(key).inspect}" }
      "#<struct #{self.class} #{pairs.join(', ')}>"
    end

    # The legacy {Options} is a Struct subclass, so code written for it may
    # check for it.
    def is_a?(klass)
      klass.equal?(Options) || super
    end
    alias kind_of? is_a?

    private

    # Hash values are copied, unless they have a coercion.
    def coerce(key, value)
      coerced = super
      coerced.is_a?(Hash) && !self.class::COERCIONS.key?(key) ? coerced.dup : coerced
    end

    def member_for(key)
      member = key.to_sym
      return member if self.class::MEMBERS.include?(member)

      raise NameError.new("no member '#{key}' in struct", member, receiver: self)
    end

    def member_at!(index)
      self.class::MEMBERS.fetch(index) do
        raise IndexError, "offset #{index} too large for struct(size:#{self.class::MEMBERS.size})"
      end
    end

    def reader_for(key)
      member = key.to_sym
      return member if self.class::MEMBERS.include?(member)

      raise NoMethodError.new("undefined method '#{key}' for an instance of #{self.class}", member, receiver: self)
    end
  end
end
