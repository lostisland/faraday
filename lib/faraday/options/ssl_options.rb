# frozen_string_literal: true

module Faraday
  # SSL-related options.
  #
  # Besides the accessors, it keeps the Struct-style API it had when it was an
  # {Options} (+[]+, +[]=+, +fetch+, +key?+...), which adapters rely on, e.g.
  # +env[:ssl].fetch(:verify, true)+.
  class SSLOptions < BaseOptions
    MEMBERS = %i[verify verify_hostname hostname
                 ca_file ca_path verify_mode
                 cert_store client_cert client_key
                 certificate private_key verify_depth
                 version min_version max_version ciphers].freeze

    # @return [Boolean] whether to verify SSL certificates or not
    attr_accessor :verify

    # @return [Boolean] whether to enable hostname verification on server certificates
    #   during the handshake or not (see https://github.com/ruby/openssl/pull/60)
    attr_accessor :verify_hostname

    # @return [String] Server hostname used for SNI (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLSocket.html#method-i-hostname-3D)
    attr_accessor :hostname

    # @return [String] CA file
    attr_accessor :ca_file

    # @return [String] CA path
    attr_accessor :ca_path

    # @return [Integer] Any +OpenSSL::SSL::+ constant (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL.html)
    attr_accessor :verify_mode

    # @return [OpenSSL::X509::Store] certificate store. It is not built lazily,
    #   adapters create their own default one when it is not set.
    attr_accessor :cert_store

    # @return [String, OpenSSL::X509::Certificate] client certificate
    attr_accessor :client_cert

    # @return [String, OpenSSL::PKey::RSA, OpenSSL::PKey::DSA] client key
    attr_accessor :client_key

    # @return [OpenSSL::X509::Certificate] certificate (Excon only)
    attr_accessor :certificate

    # @return [OpenSSL::PKey::RSA, OpenSSL::PKey::DSA] private key (Excon only)
    attr_accessor :private_key

    # @return [Integer] maximum depth for the certificate chain verification
    attr_accessor :verify_depth

    # @return [String, Symbol] SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-ssl_version-3D)
    attr_accessor :version

    # @return [String, Symbol] minimum SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-min_version-3D)
    attr_accessor :min_version

    # @return [String, Symbol] maximum SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-max_version-3D)
    attr_accessor :max_version

    # @return [String] cipher list in OpenSSL format (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-ciphers-3D)
    attr_accessor :ciphers

    # @return [Boolean] true if should verify
    def verify?
      verify != false
    end

    # @return [Boolean] true if should not verify
    def disable?
      !verify?
    end

    # @return [Boolean] true if should verify_hostname
    def verify_hostname?
      verify_hostname != false
    end

    # @return [Array<Symbol>] the members
    def self.members
      MEMBERS
    end

    # @return [Array<Symbol>] the members
    def members
      MEMBERS
    end

    # @param key [Symbol, String] a member
    # @return [Object] the value of the member
    # @raise [NameError] if +key+ is not a member
    def [](key)
      public_send(member_for(key))
    end

    # @param key [Symbol, String] a member
    # @param value [Object] the new value of the member
    # @raise [NameError] if +key+ is not a member
    def []=(key, value)
      public_send(:"#{member_for(key)}=", value)
    end

    # Returns the value of a member. A member that is not set (+nil+) is set to
    # the default, or to the block value, and that value is returned.
    #
    # @param key [Symbol, String] a member
    # @param args [Array] the optional default value
    # @return [Object] the value of the member
    # @raise [KeyError] if the member is not set and there is no default
    def fetch(key, *args)
      unless MEMBERS.include?(key.to_sym) && !self[key].nil?
        if !args.empty?
          public_send(:"#{key}=", args.first)
        elsif block_given?
          public_send(:"#{key}=", yield(key))
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
      self[key]
    end

    # @param keys [Array<Symbol, String>] members
    # @return [Array<Object>] the values of the members
    def values_at(*keys)
      keys.map { |key| self[key] }
    end

    # @return [Array<Object>] the values of all the members, set or not
    def values
      MEMBERS.map { |key| public_send(key) }
    end

    # @return [Array<Symbol>] the members that are set
    def keys
      MEMBERS.reject { |key| public_send(key).nil? }
    end

    # @return [Hash] all the members, set or not, unlike {#to_hash}
    def to_h
      MEMBERS.to_h { |key| [key, public_send(key)] }
    end

    # @return [Boolean] true if no member is set
    def empty?
      keys.empty?
    end

    # Yields the name and value of all the members, set or not.
    def each
      return to_enum(:each) unless block_given?

      MEMBERS.each { |key| yield(key, public_send(key)) }
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
    def delete(key)
      value = self[key]
      self[key] = nil
      value
    end

    # Unsets all the members.
    def clear
      MEMBERS.each { |key| delete(key) }
    end

    # @return [Object, nil] the nested value, see +Hash#dig+
    def dig(key, *rest)
      value = self[key]
      rest.empty? || value.nil? ? value : value.dig(*rest)
    end

    # @return [Set<Symbol>] the members that are set
    def symbolized_key_set
      Set.new(keys)
    end

    def ==(other)
      other.class == self.class && other.values == values
    end

    def eql?(other)
      other.class == self.class && other.values.eql?(values)
    end

    def hash
      [self.class, values].hash
    end

    private

    def member_for(key)
      member = key.to_sym if key.respond_to?(:to_sym)
      return member if MEMBERS.include?(member)

      raise NameError.new("no member #{key.inspect} in #{self.class}", key.to_s, receiver: self)
    end
  end
end
