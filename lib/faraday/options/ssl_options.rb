# frozen_string_literal: true

module Faraday
  # SSL-related options.
  #
  # Besides the accessors, it keeps the Struct-style API it had when it was an
  # {Options} (+[]+, +[]=+, +fetch+, +key?+...), which adapters rely on, e.g.
  # +env[:ssl].fetch(:verify, true)+, see {StructCompat}.
  class SSLOptions < BaseOptions
    include StructCompat

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
  end
end
