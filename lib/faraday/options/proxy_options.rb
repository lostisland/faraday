# frozen_string_literal: true

module Faraday
  # ProxyOptions contains the configurable properties for the proxy
  # configuration used when making an HTTP request.
  #
  # {.from} also accepts a proxy URL (a String, with +http://+ assumed when it
  # has no scheme) or a URI.
  #
  # @example
  #   ProxyOptions.from('http://user:pass@proxy.example.org:8080')
  #   ProxyOptions.new(uri: 'http://proxy.example.org', user: 'user')
  class ProxyOptions < BaseOptions
    include StructCompat
    extend Forwardable

    MEMBERS = %i[uri user password].freeze
    COERCIONS = { uri: ->(value) { Utils.URI(value) } }.freeze

    # @return [URI] the proxy server URI
    attr_accessor :uri

    # @!attribute [rw] user
    #   @return [String, nil] the proxy server username, the unescaped user of
    #     the {#uri} unless set
    # @!attribute [rw] password
    #   @return [String, nil] the proxy server password, the unescaped password
    #     of the {#uri} unless set
    attr_writer :user, :password

    def_delegators :uri, :scheme, :scheme=, :host, :host=, :port, :port=,
                   :path, :path=

    class << self
      # Create new instance from a URL, URI, hash or existing instance.
      #
      # @param value [nil, String, URI, Hash, OptionsLike] the value to convert
      # @return [ProxyOptions]
      def from(value)
        case value
        when '', false
          new
        when String
          # URIs without a scheme should default to http (like 'example:123').
          # This fixes #1282 and prevents a silent failure in some adapters.
          value = "http://#{value}" unless value.include?('://')
          new(uri: value)
        when URI
          new(uri: value)
        else
          super
        end
      end
    end

    def user
      @user = unescaped_uri_part(:user) if @user.nil?
      @user
    end

    def password
      @password = unescaped_uri_part(:password) if @password.nil?
      @password
    end

    private

    def unescaped_uri_part(part)
      value = uri&.public_send(part)
      value && URI::DEFAULT_PARSER.unescape(value)
    end
  end
end
