# frozen_string_literal: true

module Faraday
  # The part of the Struct-style API of the legacy {Options} that adapters and
  # middleware still use on the {BaseOptions} subclasses converted from it
  # ({ProxyOptions}, {RequestOptions}, {SSLOptions}), e.g.
  # +env[:request][:proxy][:uri]+, +env[:ssl].fetch(:verify, true)+ or
  # +ssl.key?(:verify_hostname)+.
  #
  # Official adapters support every Faraday 2.x, so it is kept for the whole
  # 2.x series. Reads go through the public accessors of the members.
  #
  # @deprecated Slated for removal in Faraday 3.0, use the accessors of the
  #   options instead. There is no runtime warning yet.
  #
  # It must not be used by new options classes.
  #
  # @api private
  module StructCompat
    # @param key [Symbol, String] a member
    # @return [Object] the value of the member
    # @raise [NameError] if +key+ is not a member
    def [](key)
      public_send(member_for(key))
    end

    # Returns the value of a member. A member that is not set (+nil+) is set to
    # the default, or to the block value, and that value is returned.
    #
    # @param key [Symbol, String] a member
    # @param args [Array] the optional default value
    # @return [Object] the value of the member
    # @raise [KeyError] if the member is not set and there is no default
    def fetch(key, *args)
      unless self.class::MEMBERS.include?(key.to_sym) && !public_send(key).nil?
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

    # @param key [Symbol] any key, e.g. +ssl.key?(:client_cert_passwd)+
    # @return [Boolean] true if +key+ is a member and it is set
    def key?(key)
      self.class::MEMBERS.include?(key) && !public_send(key).nil?
    end

    private

    def member_for(key)
      member = key.to_sym
      return member if self.class::MEMBERS.include?(member)

      raise NameError.new("no member '#{key}' in struct", member, receiver: self)
    end
  end
end
